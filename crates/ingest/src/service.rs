use std::{sync::Arc, time::Instant};

use scuffle_context::ContextFutExt;

use crate::{
    db::batcher::{EventInsertBatcher, RoutesBatcher},
    global::Global,
    ripe_ris,
};

mod handler;
mod seeding;

pub struct IngestSvc;

impl scuffle_bootstrap::service::Service<Global> for IngestSvc {
    async fn run(self, global: Arc<Global>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
        tracing::info!("starting ingest service");

        seeding::seed(&global, &ctx, &global.config.seed_rrc).await?;

        if global.config.only_seed {
            scuffle_context::Handler::global().cancel();
            return Ok(());
        }

        let (tx, mut rx) = tokio::sync::mpsc::channel(10_000);

        {
            let ctx = ctx.clone();
            tokio::spawn(async move {
                if let Err(e) = ripe_ris::live::watch_messages(ctx, tx).await {
                    tracing::error!(err = ?e, "failed to watch RIS messages");
                }

                // Cancel the global handler when the connection is done
                scuffle_context::Handler::global().cancel();
            });
        }

        let mut event_batcher = EventInsertBatcher::new(global.db.clone()).await?;
        let mut route_batcher = RoutesBatcher::new(global.db.clone());

        let mut counter = 0;
        let start = Instant::now();

        while let Some(Some(message)) = rx.recv().with_context(&ctx).await {
            if let Err(e) =
                handler::handle_message(&global, &mut event_batcher, &mut route_batcher, message)
                    .await
            {
                tracing::error!(err = ?e, "error handling message");
            }
            counter += 1;
        }

        let elapsed = start.elapsed().as_secs_f64();
        tracing::info!(
            "{} messages in {:.2}s ({:.2}/s)",
            counter,
            elapsed,
            counter as f64 / elapsed
        );

        Ok(())
    }
}
