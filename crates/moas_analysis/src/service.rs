use std::{net::IpAddr, process::Stdio, sync::Arc};

use anyhow::Context;
use scuffle_context::ContextFutExt;
use tokio::{process::Command, sync::Semaphore};

use crate::global::Global;

pub struct MoasAnalysisSvc;

impl scuffle_bootstrap::Service<Global> for MoasAnalysisSvc {
    async fn run(self, global: Arc<Global>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
        tracing::info!("starting moas analysis service");

        if global.config.update_moas {
            tracing::info!("updating moas prefixes");

            let db = global
                .db
                .get()
                .await
                .context("failed to get db connection")?;

            let result = db
                .execute(
                    "INSERT INTO moas (prefix, origins, updated_at)
                    SELECT
                        prefix,
                        array_agg(DISTINCT origin ORDER BY origin) AS origins,
                        max(updated_at) AS updated_at
                    FROM routes,
                        LATERAL UNNEST(origin_asn) AS origin
                    WHERE array_length(origin_asn, 1) = 1
                    GROUP BY prefix
                    HAVING count(DISTINCT origin) > 1
                    ON CONFLICT (prefix) DO UPDATE SET
                        origins = EXCLUDED.origins,
                        updated_at = EXCLUDED.updated_at",
                    &[],
                )
                .await
                .context("failed to update moas table")?;

            tracing::info!(n = result, "updated moas prefixes");
        }

        tracing::info!(
            concurrency = global.config.zmap_concurrency,
            "starting zmap scans"
        );

        let db = global
            .db
            .get()
            .await
            .context("failed to get db connection")?;

        let prefixes = db
            .query(
                "SELECT prefix
            FROM moas
            WHERE FAMILY(prefix) = 4 AND last_scanned_at IS NULL
            ORDER BY updated_at DESC
            LIMIT 100",
                &[],
            )
            .await
            .context("failed to query moas prefixes")?
            .into_iter()
            .map(|r| r.get("prefix"));

        let semaphore = Arc::new(Semaphore::new(global.config.zmap_concurrency));

        let futures = prefixes.map(|prefix| {
            let global = global.clone();
            let ctx = ctx.clone();
            let semaphore = semaphore.clone();

            tokio::spawn(async move {
                let inner = async move {
                    let _permit = semaphore
                        .acquire()
                        .await
                        .context("failed to aquire semaphore")?;

                    let hosts = match run_zmap(prefix).with_context(&ctx).await {
                        Some(res) => res.context("failed to run zmap")?,
                        None => return Ok(()),
                    };

                    let db = global
                        .db
                        .get()
                        .await
                        .context("failed to get db connection after scan")?;

                    db.execute(
                        "UPDATE moas
                            SET https_hosts = $1::INET[], last_scanned_at = NOW()
                            WHERE prefix = $2::CIDR",
                        &[&hosts, &prefix],
                    )
                    .await
                    .context("failed to update moas prefix after scan")?;

                    anyhow::Result::<_>::Ok(())
                };

                if let Err(e) = inner.await {
                    tracing::error!(err = ?e, "error running scan task");
                }
            })
        });

        futures::future::join_all(futures).await;

        tracing::info!("all scans done");

        scuffle_context::Handler::global().cancel();
        Ok(())
    }
}

async fn run_zmap(prefix: cidr::IpCidr) -> anyhow::Result<Vec<IpAddr>> {
    tracing::debug!(prefix = %prefix, "running zmap");

    let out = Command::new("sudo")
        .arg("zmap")
        .arg("--output-file=-")
        .arg("--target-ports=443")
        // .arg("--max-results=1")
        .arg(prefix.to_string())
        .stderr(Stdio::null())
        .stdout(Stdio::piped())
        .spawn()
        .context("failed to spawn zmap process")?
        .wait_with_output()
        .await
        .context("failed to read zmap output")?;

    let addr: Vec<_> = String::from_utf8(out.stdout)
        .context("failed to parse zmap output as UTF-8")?
        .lines()
        .map(|l| l.parse())
        .collect::<Result<_, _>>()
        .context("failed to parse line as ip address")?;

    tracing::debug!(prefix = %prefix, addresses_found = addr.len(), "scan finished");

    Ok(addr)
}
