use std::{
    sync::{Arc, atomic::AtomicUsize},
    time::Duration,
};

use scuffle_context::ContextFutExt;

use crate::global::Global;

pub struct DetectionSvc;

impl scuffle_bootstrap::Service<Global> for DetectionSvc {
    async fn run(self, global: Arc<Global>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
        tracing::info!("starting detection service");

        let mut fetcher = db::batcher::MoasRoutesFetcher::new(global.db.clone());

        tracing::info!(
            db_url = global.config.db_url,
            "connecting to db for listener"
        );
        let (client, conn) = db::connect_raw(&global.config.db_url).await?;
        let mut rx = db::listen_for_bgp_updates(&client, conn, ctx.clone()).await?;

        let counter = Arc::new(AtomicUsize::new(0));

        {
            let ctx = ctx.clone();
            let counter = counter.clone();
            tokio::spawn(async move {
                let mut interval = tokio::time::interval(Duration::from_secs(10));

                // skip first tick
                interval.tick().with_context(&ctx).await;

                while !ctx.is_done() {
                    interval.tick().with_context(&ctx).await;

                    let count = counter.swap(0, std::sync::atomic::Ordering::Relaxed);
                    tracing::info!(
                        "{} moas prefixes in the past 10s ({:.2}/s)",
                        count,
                        count as f64 / 10.0
                    );
                }
            });
        }

        while let Some(Some(notification)) = rx.recv().with_context(&ctx).await {
            let Ok(prefix) = notification.payload().parse().inspect_err(
                |e| tracing::warn!(err = ?e, payload = notification.payload(), "failed to parse notification payload as prefix, skipping"),
            ) else {
                continue;
            };

            if let Some(moases) = fetcher.fetch(prefix).await? {
                counter.fetch_add(moases.len(), std::sync::atomic::Ordering::Relaxed);

                for moas in moases {
                    tracing::debug!(?moas, "identified moas");
                }
            }
        }

        Ok(())
    }
}
