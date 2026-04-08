use std::sync::Arc;

use anyhow::Context;
use axum::{http::StatusCode, response::IntoResponse};
use scuffle_context::ContextFutExt;

use crate::ProfilingConfig;

pub struct ProfilingSvc;

impl<G: ProfilingConfig> scuffle_bootstrap::Service<G> for ProfilingSvc {
    async fn enabled(&self, global: &Arc<G>) -> anyhow::Result<bool> {
        if global.bind().is_none() {
            return Ok(false);
        }

        let prof_ctl = jemalloc_pprof::PROF_CTL
            .as_ref()
            .context("no prof ctl")?
            .lock()
            .await;
        Ok(prof_ctl.activated())
    }

    async fn run(self, global: Arc<G>, ctx: scuffle_context::Context) -> anyhow::Result<()> {
        let bind = global.bind().context("no bind")?;
        tracing::info!(bind = ?bind, "starting profiling service");

        let app = axum::Router::new().route("/pprof", axum::routing::get(get_profile));

        let listener = tokio::net::TcpListener::bind(bind)
            .await
            .context("failed to bind tcp listener")?;

        tokio::spawn(async move {
            if let Some(Err(e)) = axum::serve(listener, app).with_context(ctx).await {
                tracing::error!(err = ?e, "failed to serve axum app");
            }
        });

        Ok(())
    }
}

async fn get_profile() -> Result<impl IntoResponse, (StatusCode, String)> {
    let mut prof_ctl = jemalloc_pprof::PROF_CTL
        .as_ref()
        .ok_or_else(|| (StatusCode::INTERNAL_SERVER_ERROR, "no prof ctl".to_string()))?
        .lock()
        .await;

    prof_ctl
        .dump_pprof()
        .map_err(|err| (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()))
}
