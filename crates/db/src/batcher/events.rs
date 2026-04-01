use std::{sync::Arc, time::Duration};

use anyhow::Context;
use clickhouse::inserter::Inserter;
use scuffle_context::ContextFutExt;
use tokio::{sync::Mutex, task::JoinHandle};
use tracing::Instrument;

use crate::Event;

pub struct EventBatcher {
    inserter: Arc<Mutex<Inserter<Event>>>,
    task_handle: JoinHandle<()>,
    task_handler: scuffle_context::Handler,
}

async fn clickhouse_inserter_task<T: clickhouse::Row>(
    ctx: scuffle_context::Context,
    inserter: Arc<Mutex<clickhouse::inserter::Inserter<T>>>,
) {
    let mut interval = tokio::time::interval(Duration::from_millis(500));

    while !ctx.is_done() {
        match inserter
            .lock()
            .await
            .commit()
            .await
            .context("failed to insert events")
        {
            Ok(n) if n.rows > 0 => {
                tracing::debug!(rows = n.rows, "wrote events to clickhouse");
            }
            Ok(_) => {}
            Err(e) => tracing::error!(err = ?e, "failed to insert events"),
        }

        interval.tick().with_context(&ctx).await;
    }
}

impl EventBatcher {
    pub fn new(clickhouse: &clickhouse::Client, ctx: scuffle_context::Context) -> Self {
        let inserter = Arc::new(Mutex::new(
            clickhouse
                .inserter::<Event>("events")
                .with_max_rows(10_000)
                .with_max_bytes(100 * 1024 * 1024), // 100MiB
        ));

        let (ctx, handler) = ctx.new_child();
        let task_handle =
            tokio::spawn(clickhouse_inserter_task(ctx, inserter.clone()).in_current_span());

        Self {
            inserter,
            task_handle,
            task_handler: handler,
        }
    }

    pub async fn insert(&self, event: &Event) -> anyhow::Result<()> {
        self.inserter
            .lock()
            .await
            .write(event)
            .await
            .context("failed to write event")
    }

    pub async fn end(self) -> anyhow::Result<()> {
        self.task_handler.cancel();
        self.task_handle.await.context("failed to await task")?;

        let n = Arc::into_inner(self.inserter)
            .unwrap()
            .into_inner()
            .end()
            .await
            .context("failed to end inserter")?;

        if n.rows > 0 {
            tracing::info!(rows = n.rows, "wrote events to clickhouse");
        }

        Ok(())
    }
}
