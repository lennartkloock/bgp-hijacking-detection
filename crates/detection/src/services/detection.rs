use std::{sync::Arc, time::Instant};

use scuffle_context::ContextFutExt;

use crate::{
    global::Global,
    ripe_ris::{
        self,
        live::protocol::{RisLiveServerMessage, RisMessageType},
    },
};

pub struct DetectionSvc;

impl scuffle_bootstrap::service::Service<Global> for DetectionSvc {
    async fn run(self, _global: Arc<Global>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
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

        let mut counter = 0;
        let start = Instant::now();

        while let Some(Some(message)) = rx.recv().with_context(&ctx).await {
            // tracing::info!(message = ?message);
            match &message {
                RisLiveServerMessage::RisError { message } => {
                    tracing::error!(message = message, "RIS error")
                }
                RisLiveServerMessage::RisMessage {
                    typ: RisMessageType::Update { .. },
                    ..
                } => {
                    counter += 1;
                }
                _ => {}
            }
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
