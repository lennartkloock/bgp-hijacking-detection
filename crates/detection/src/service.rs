use std::sync::Arc;

use anyhow::Context;
use db::batcher::{MoasInsertBatcher, MoasRoutesFetcher};
use scuffle_context::ContextFutExt;

use crate::global::Global;

pub struct DetectionSvc;

impl scuffle_bootstrap::Service<Global> for DetectionSvc {
    async fn run(self, global: Arc<Global>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
        tracing::info!("starting detection service");

        let mut fetcher = MoasRoutesFetcher::new(global.db.clone());
        let mut batcher = MoasInsertBatcher::new(global.db.clone());

        tracing::info!(
            db_url = global.config.db_url,
            "connecting to db for listener"
        );
        let (client, conn) = db::connect_raw(&global.config.db_url).await?;
        let mut rx = db::listen_for_bgp_updates(&client, conn, ctx.clone()).await?;

        while let Some(Some(notification)) = rx.recv().with_context(&ctx).await {
            let Ok(prefix) = notification.payload().parse().inspect_err(
                |e| tracing::warn!(err = ?e, payload = notification.payload(), "failed to parse notification payload as prefix, skipping"),
            ) else {
                continue;
            };

            if let Some(moases) = fetcher.fetch(prefix).await? {
                batcher
                    .extend(moases)
                    .await
                    .context("failed to insert moas prefixes")?;
            }
        }

        Ok(())
    }
}
