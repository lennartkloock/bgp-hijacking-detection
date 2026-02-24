use std::{sync::Arc, time::Instant};

use scuffle_context::ContextFutExt;

use crate::{global::Global, ripe_ris, service::batcher::PrefixInsertBatcher};

mod batcher;
mod handler;

pub struct DetectionSvc;

impl scuffle_bootstrap::service::Service<Global> for DetectionSvc {
    async fn run(self, global: Arc<Global>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
        tracing::info!("starting detection service");

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

        let mut batcher = PrefixInsertBatcher::new(global.db.clone());

        let mut counter = 0;
        let start = Instant::now();

        while let Some(Some(message)) = rx.recv().with_context(&ctx).await {
            if let Err(e) = handler::handle_message(&global, &mut batcher, message).await {
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
