use std::sync::Arc;

use tracing_subscriber::{Layer, layer::SubscriberExt, util::SubscriberInitExt};

use crate::config;

pub struct Global {
    pub db: db::DbPool,
    pub clickhouse: clickhouse::Client,
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

        let db = db::connect(&config.db_url).await?;

        tracing::info!(
            url = config.clickhouse.url,
            db = config.clickhouse.db,
            user = config.clickhouse.user,
            "connecting to clickhouse"
        );

        let clickhouse = clickhouse::Client::default()
            .with_url(&config.clickhouse.url)
            .with_database(&config.clickhouse.db)
            .with_user(&config.clickhouse.user)
            .with_password(&config.clickhouse.password);

        Ok(Arc::new(Self {
            db,
            clickhouse,
            config,
        }))
    }
}
