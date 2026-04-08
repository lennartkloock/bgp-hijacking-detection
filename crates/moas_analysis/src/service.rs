use std::{net::IpAddr, process::Stdio, sync::Arc};

use anyhow::Context;
use cidr::IpCidr;
use itertools::Itertools;
use scuffle_context::ContextFutExt;
use tokio::{process::Command, sync::Semaphore};

use crate::global::Global;

struct PotentialMoas {
    prefix: IpCidr,
    origins: Vec<i64>,
    updated_at: chrono::DateTime<chrono::Utc>,
}

impl PotentialMoas {
    fn into_tuple(self) -> (IpCidr, Vec<i64>, chrono::DateTime<chrono::Utc>) {
        (self.prefix, self.origins, self.updated_at)
    }
}

struct Route {
    prefix: IpCidr,
    as_path: serde_json::Value,
}

pub struct MoasAnalysisSvc;

impl scuffle_bootstrap::Service<Global> for MoasAnalysisSvc {
    async fn run(self, global: Arc<Global>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
        tracing::info!("starting moas analysis service");

        if global.config.update_moas {
            tracing::info!("querying moas prefixes");

            let db = global
                .db
                .get()
                .await
                .context("failed to get db connection")?;

            let mut potential_moas: Vec<_> = db
                .query(
                    "SELECT
                            prefix,
                            array_agg(DISTINCT origin_asn[1] ORDER BY origin_asn[1]) AS origins,
                            max(updated_at) AS updated_at
                        FROM routes
                        WHERE array_length(origin_asn, 1) = 1
                        GROUP BY prefix
                        HAVING count(DISTINCT origin_asn[1]) > 1;",
                    &[],
                )
                .await
                .context("failed to query moas routes")?
                .into_iter()
                .map(|r| PotentialMoas {
                    prefix: r.get("prefix"),
                    origins: r.get("origins"),
                    updated_at: r.get("updated_at"),
                })
                .collect();

            tracing::info!(n = potential_moas.len(), "filtering potential moas routes");

            let routes = {
                let prefixes: Vec<_> = potential_moas.iter().map(|m| m.prefix).collect();

                db.query(
                    "SELECT prefix, as_path
                    FROM routes
                    WHERE prefix = ANY($1::CIDR[]) AND array_length(origin_asn, 1) = 1",
                    &[&prefixes],
                )
                .await
                .context("failed to query routes")?
                .into_iter()
                .map(|r| Route {
                    prefix: r.get("prefix"),
                    as_path: r.get("as_path"),
                })
                .into_group_map_by(|r| r.prefix)
            };

            potential_moas.retain_mut(|moas| {
                let routes = routes.get(&moas.prefix).expect("failed to get routes");

                moas.origins.retain(|o| {
                    // Look if the origin ASN o is part of every path
                    let is_in_all = routes.iter().all(|r| {
                        r.as_path
                            .as_array()
                            .expect("as_path is not array")
                            .contains(&serde_json::Value::Number((*o).into()))
                    });
                    // Only keep this origin as an MOAS origin if it isn't part of every route
                    !is_in_all
                });

                // Keep this MOAS prefix if it has more than one origin
                moas.origins.len() > 1
            });

            tracing::info!(n = potential_moas.len(), "finished filtering prefixes");

            let (prefixes, origins, updated_ats): (Vec<_>, Vec<_>, Vec<_>) =
                itertools::multiunzip(potential_moas.into_iter().map(PotentialMoas::into_tuple));

            let origin_asn_text: Vec<_> = origins
                .into_iter()
                .map(|origins| {
                    origins
                        .iter()
                        .map(|asn| asn.to_string())
                        .collect::<Vec<_>>()
                        .join(",")
                })
                .collect();

            let res = db
                .execute(
                    "INSERT INTO moas (prefix, origins, updated_at)
                    SELECT prefix, string_to_array(origin_asn_text, ',')::BIGINT[], updated_at
                    FROM UNNEST($1::CIDR[], $2::TEXT[], $3::TIMESTAMPTZ[])
                    AS t(prefix, origin_asn_text, updated_at)
                    ON CONFLICT (prefix) DO UPDATE SET
                        origins = EXCLUDED.origins,
                        updated_at = EXCLUDED.updated_at",
                    &[&prefixes, &origin_asn_text, &updated_ats],
                )
                .await
                .context("failed to update moas table")?;

            tracing::info!(n = res, "updated moas prefixes");
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
                    LEFT JOIN moas_whitelist
                        ON moas.origins = moas_whitelist.origins
                    WHERE moas_whitelist.origins IS NULL
                        AND FAMILY(prefix) = 4
                        AND last_scanned_at IS NULL
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
        .kill_on_drop(true)
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
