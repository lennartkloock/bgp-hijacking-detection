use anyhow::Context;
use bb8_postgres::PostgresConnectionManager;
use futures_util::StreamExt;
use scuffle_context::ContextFutExt;
use tokio_postgres::{AsyncMessage, NoTls};

pub mod batcher;
mod types;

pub use types::*;

pub type DbPool = bb8::Pool<PostgresConnectionManager<NoTls>>;

pub async fn connect_raw(
    db_url: &str,
) -> anyhow::Result<(
    tokio_postgres::Client,
    tokio_postgres::Connection<tokio_postgres::Socket, tokio_postgres::tls::NoTlsStream>,
)> {
    tokio_postgres::connect(db_url, NoTls)
        .await
        .context("failed to connect to db")
}

pub async fn connect(db_url: &str) -> anyhow::Result<DbPool> {
    let db_mgr = PostgresConnectionManager::new_from_stringlike(db_url, tokio_postgres::NoTls)
        .context("failed to parse pg connection string")?;
    let db_pool = DbPool::builder()
        .build(db_mgr)
        .await
        .context("failed to build pg connection pool")?;
    Ok(db_pool)
}

pub async fn check_routes_empty(db: &DbPool) -> anyhow::Result<bool> {
    let conn = db.get().await.context("failed to get db connection")?;
    let row = conn
        .query_one("SELECT NOT EXISTS (SELECT 1 FROM routes LIMIT 1);", &[])
        .await
        .context("failed to fetch count")?;
    Ok(row.get(0))
}

pub async fn last_event_timestamp(
    db: &DbPool,
) -> anyhow::Result<Option<chrono::DateTime<chrono::Utc>>> {
    let conn = db.get().await.context("failed to get db connection")?;
    let row = conn
        .query_opt(
            "SELECT timestamp FROM events ORDER BY timestamp DESC LIMIT 1;",
            &[],
        )
        .await
        .context("failed to fetch count")?;
    Ok(row.map(|r| r.get(0)))
}

pub async fn listen_for_bgp_updates(
    db_client: &tokio_postgres::Client,
    mut db_conn: tokio_postgres::Connection<
        tokio_postgres::Socket,
        tokio_postgres::tls::NoTlsStream,
    >,
    ctx: scuffle_context::Context,
) -> anyhow::Result<tokio::sync::mpsc::UnboundedReceiver<tokio_postgres::Notification>> {
    let (tx, rx) = tokio::sync::mpsc::unbounded_channel();

    tokio::spawn(async move {
        let mut stream = futures_util::stream::poll_fn(|cx| db_conn.poll_message(cx));
        while let Some(Some(message)) = stream.next().with_context(&ctx).await {
            match message {
                Ok(AsyncMessage::Notification(n)) => {
                    if let Err(e) = tx.send(n) {
                        tracing::error!(err = ?e, "failed to send message on channel");
                        break;
                    }
                }
                Ok(AsyncMessage::Notice(e)) => {
                    tracing::error!(err = ?e, "error message from database");
                }
                Ok(_) => {
                    tracing::error!("unknown message from database");
                }
                Err(e) => {
                    tracing::error!(err = ?e, "error while polling connection");
                    break;
                }
            }
        }
    });

    tracing::info!("starting LISTEN");
    db_client
        .execute("LISTEN bgp_updates;", &[])
        .await
        .context("failed to subscribe to bgp_updates")?;
    tracing::info!("subscribed to bgp_updates channel");

    Ok(rx)
}
