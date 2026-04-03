use std::time::{Duration, Instant};

use anyhow::Context;
use tokio::task::JoinHandle;
use tracing::Instrument;

use crate::Event;

pub struct EventBatcher {
    tx: tokio::sync::mpsc::Sender<Event>,
    task_handle: JoinHandle<()>,
    task_handler: scuffle_context::Handler,
}

fn new_inserter(clickhouse: &clickhouse::Client) -> clickhouse::inserter::Inserter<Event> {
    clickhouse
        .inserter::<Event>("events")
        .with_max_rows(10_000)
        .with_max_bytes(100 * 1024 * 1024) // 100MiB
        .with_period(Some(Duration::from_secs(5)))
}

async fn clickhouse_inserter_task(
    ctx: scuffle_context::Context,
    clickhouse: clickhouse::Client,
    mut rx: tokio::sync::mpsc::Receiver<Event>,
) {
    let mut inserter = new_inserter(&clickhouse);
    let mut interval = tokio::time::interval(Duration::from_millis(500));

    let mut timer = Instant::now();

    loop {
        tokio::select! {
            Some(row) = rx.recv() => {
                if let Err(e) = inserter.write(&row).await {
                    tracing::error!(err = ?e, "failed to write row");
                }

                if timer.elapsed() > Duration::from_secs(30) {
                    let channel_len = rx.len();
                    if channel_len > 10 {
                        tracing::warn!(
                            n_messages = channel_len,
                            "the event inserter receiver is behind"
                        );
                    }
                    timer = Instant::now();
                }
            }
            _ = interval.tick() => {
                match inserter
                    .commit()
                    .await
                {
                    Ok(n) if n.rows > 0 => {
                        tracing::debug!(rows = n.rows, "wrote events");
                    }
                    Ok(_) => {}
                    Err(e) => {
                        tracing::error!(err = ?e, "failed to insert events, the inserter is likely borked now, the data that hasn't been written yet is lost, recreating now...");
                        inserter = new_inserter(&clickhouse);
                    },
                }
            }
            _ = ctx.done() => {
                match inserter.end().await {
                    Ok(n) if n.rows > 0 => {
                        tracing::debug!(rows = n.rows, "wrote events");
                    },
                    Ok(_) => {},
                    Err(e) => {
                        tracing::debug!(err = ?e, "failed to end inserter");
                    }
                }
                break;
            }
        }
    }
}

impl EventBatcher {
    pub fn new(clickhouse: clickhouse::Client, ctx: scuffle_context::Context) -> Self {
        let (ctx, handler) = ctx.new_child();

        let (tx, rx) = tokio::sync::mpsc::channel(1000);
        let task_handle =
            tokio::spawn(clickhouse_inserter_task(ctx, clickhouse, rx).in_current_span());

        Self {
            task_handle,
            task_handler: handler,
            tx,
        }
    }

    pub async fn insert(&self, event: Event) -> anyhow::Result<()> {
        self.tx.send(event).await.context("failed to send event")
    }

    pub async fn end(self) -> anyhow::Result<()> {
        self.task_handler.cancel();
        self.task_handle.await.context("failed to await task")?;

        Ok(())
    }
}
