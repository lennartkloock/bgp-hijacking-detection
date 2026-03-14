use std::sync::Arc;

use tracing_subscriber::{Layer, layer::SubscriberExt, util::SubscriberInitExt};

use crate::config;

pub struct Global {
    pub db: db::DbPool,
    pub config: config::Config,
}

impl scuffle_signal::SignalConfig for Global {}

impl scuffle_bootstrap::global::Global for Global {
    type Config = config::Config;

    async fn init(config: config::Config) -> anyhow::Result<Arc<Self>> {
        tracing_subscriber::registry()
            .with(
                tracing_subscriber::fmt::layer()
                    .with_filter(tracing_subscriber::EnvFilter::try_new(&config.log_level)?),
            )
            .init();

        tracing::info!("init");

        let db = db::connect(&config.db_url).await?;

        Ok(Arc::new(Self { db, config }))
    }
}
