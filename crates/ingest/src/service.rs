use std::{
    sync::Arc,
    time::{Duration, Instant},
};

use db::batcher::{EventInsertBatcher, RoutesBatcher};
use scuffle_context::ContextFutExt;

use crate::{global::Global, ripe_ris};

mod handler;
mod seeding;

pub struct IngestSvc;

impl scuffle_bootstrap::service::Service<Global> for IngestSvc {
    async fn run(self, global: Arc<Global>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
        tracing::info!("starting ingest service");

        seeding::seed(
            &global,
            &ctx,
            &global.config.seed_rrc,
            global.config.insert_events,
        )
        .await?;

        if global.config.only_seed {
            scuffle_context::Handler::global().cancel();
            return Ok(());
        }

        let (tx, mut rx) = tokio::sync::mpsc::channel(10_000);

        {
            let ctx = ctx.clone();
            tokio::spawn(async move {
                let mut tries = 0;
                let mut last_try = Instant::now();

                loop {
                    if let Err(e) = ripe_ris::live::watch_messages(ctx.clone(), tx.clone()).await {
                        tracing::error!(err = ?e, "failed to watch RIS messages");
                    }

                    if last_try.elapsed() < Duration::from_secs(60) {
                        if tries >= 5 {
                            tracing::error!("connection failed 5 times, terminating...");
                            break;
                        }
                        tries += 1;
                    } else {
                        // Reset tries because this connection was alive longer than a minute
                        tries = 0;
                    }
                    last_try = Instant::now();

                    tracing::info!("connection closed, reconnecting...");
                }

                // Cancel the global handler when the connection is done
                scuffle_context::Handler::global().cancel();
            });
        }

        let mut event_batcher = if global.config.insert_events {
            Some(EventInsertBatcher::new(global.db.clone()).await?)
        } else {
            None
        };
        let mut route_batcher = RoutesBatcher::new(global.db.clone());

        let mut counter = 0;
        let start = Instant::now();

        while let Some(Some(message)) = rx.recv().with_context(&ctx).await {
            if let Err(e) = handler::handle_message(
                &global,
                event_batcher.as_mut(),
                &mut route_batcher,
                message,
            )
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
