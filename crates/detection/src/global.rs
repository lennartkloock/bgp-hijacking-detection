use std::sync::Arc;

use tracing_subscriber::{Layer, layer::SubscriberExt, util::SubscriberInitExt};

pub struct Global;

impl scuffle_signal::SignalConfig for Global {}

impl scuffle_bootstrap::global::GlobalWithoutConfig for Global {
    async fn init() -> anyhow::Result<Arc<Self>> {
        tracing_subscriber::registry()
            .with(tracing_subscriber::fmt::layer().with_filter(
                tracing_subscriber::EnvFilter::from_default_env().add_directive("debug".parse()?),
            ))
            .init();

        if rustls::crypto::aws_lc_rs::default_provider()
            .install_default()
            .is_err()
        {
            anyhow::bail!("failed to install aws-lc-rs as default TLS provider");
        }

        tracing::info!("init");

        Ok(Arc::new(Self))
    }
}
