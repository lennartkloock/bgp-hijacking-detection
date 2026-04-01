use std::{
    sync::Arc,
    time::{Duration, Instant},
};

use db::batcher::RoutesBatcher;
use scuffle_context::ContextFutExt;
use tokio::sync::Mutex;

use crate::{global::Global, ripe_ris};

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

        if ctx.is_done() {
            // in case the ctx was cancelled while seeding
            return Ok(());
        }

        let (ris_tx, mut ris_rx) = tokio::sync::mpsc::channel(500_000);

        {
            let ctx = ctx.clone();
            tokio::spawn(async move {
                let mut tries = 0;
                let mut last_try = Instant::now();

                while !ctx.is_done() {
                    if tries > 0 {
                        tracing::info!("connection closed, reconnecting...");
                    }

                    if let Err(e) =
                        ripe_ris::live::watch_messages(ctx.clone(), ris_tx.clone()).await
                    {
                        tracing::error!(err = %e, "failed to watch RIS messages");
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
                }

                // Cancel the global handler when the connection is done
                scuffle_context::Handler::global().cancel();
            });
        }

        let event_inserter = Arc::new(Mutex::new(
            global
                .clickhouse
                .inserter::<db::Event>("events")
                .with_max_rows(10_000)
                .with_max_bytes(100 * 1024 * 1024),
        )); // 100MiB
        let mut route_batcher = RoutesBatcher::new(global.db.clone(), ctx.clone());

        tokio::spawn(db::clickhouse_inserter_task(
            ctx.clone(),
            event_inserter.clone(),
        ));

        let mut timer = Instant::now();

        while let Some(Some(message)) = ris_rx.recv().with_context(&ctx).await {
            if let Err(e) =
                handler::handle_message(&global, &event_inserter, &mut route_batcher, message).await
            {
                tracing::error!(err = ?e, "error handling message");
            }

            if timer.elapsed() > Duration::from_secs(30) {
                let channel_len = ris_rx.len();
                if channel_len > 10 {
                    tracing::warn!(n_messages = channel_len, "the RIPE RIS receiver is behind");
                }
                timer = Instant::now();
            }
        }

        Ok(())
    }
}
