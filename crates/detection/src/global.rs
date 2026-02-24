use std::sync::Arc;

use anyhow::Context;
use tracing_subscriber::{Layer, layer::SubscriberExt, util::SubscriberInitExt};

use crate::config;

pub struct Global {
    pub db: sqlx::PgPool,
}

impl scuffle_signal::SignalConfig for Global {}

impl scuffle_bootstrap::global::Global for Global {
    type Config = config::Config;

    async fn init(config: config::Config) -> anyhow::Result<Arc<Self>> {
        tracing_subscriber::registry()
            .with(tracing_subscriber::fmt::layer().with_filter(
                tracing_subscriber::EnvFilter::from_default_env().add_directive(config.log_level.parse()?),
            ))
            .init();

        tracing::info!("init");

        if rustls::crypto::aws_lc_rs::default_provider()
            .install_default()
            .is_err()
        {
            anyhow::bail!("failed to install aws-lc-rs as default TLS provider");
        }

        let db = sqlx::PgPool::connect(&config.db_url).await.context("failed to connect to database")?;

        Ok(Arc::new(Self {
            db,
        }))
    }
}
