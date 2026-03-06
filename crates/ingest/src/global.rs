use std::{str::FromStr, sync::Arc};

use anyhow::Context;
use tracing_subscriber::{Layer, layer::SubscriberExt, util::SubscriberInitExt};

use crate::{config, db};

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

        if rustls::crypto::aws_lc_rs::default_provider()
            .install_default()
            .is_err()
        {
            anyhow::bail!("failed to install aws-lc-rs as default TLS provider");
        }

        let db_config = tokio_postgres::Config::from_str(&config.db_url)
            .context("failed to parse pg connection string")?;
        let db_mgr = bb8_postgres::PostgresConnectionManager::new(db_config, tokio_postgres::NoTls);
        let db_pool = bb8::Pool::builder()
            .build(db_mgr)
            .await
            .context("failed to build pg connection pool")?;

        Ok(Arc::new(Self {
            db: db_pool,
            config,
        }))
    }
}
