//! https://ris-live.ripe.net/

use std::io;

use futures_util::{SinkExt, StreamExt};
use scuffle_context::ContextFutExt;
use tokio::net::TcpStream;
use tokio_tungstenite::{
    MaybeTlsStream, WebSocketStream,
    tungstenite::{
        self,
        protocol::{CloseFrame, frame::coding::CloseCode},
    },
};

use crate::ripe_ris::live::protocol::{RisLiveClientMessage, RisLiveSubscriptionFilter};

const RIS_LIVE_URL: &str =
    "wss://ris-live.ripe.net/v1/ws/?client=lennart-kloock-bgp-hijacking-detection";

pub(crate) mod protocol;

#[derive(Debug, thiserror::Error)]
#[allow(clippy::large_enum_variant)] // not constructed very often
pub(crate) enum Error {
    #[error(transparent)]
    Tungstenite(#[from] tungstenite::Error),
    #[error("unexpected ws message")]
    InvalidMessage,
    #[error("failed to de/serialize: {0}")]
    Json(#[from] serde_json::Error),
    #[error("failed to send message to channel: {0}")]
    Channel(#[from] tokio::sync::mpsc::error::SendError<protocol::RisLiveServerMessage>),
    #[error(transparent)]
    Io(#[from] io::Error),
}

pub(crate) async fn watch_messages(
    ctx: scuffle_context::Context,
    tx: tokio::sync::mpsc::Sender<protocol::RisLiveServerMessage>,
    filter: RisLiveSubscriptionFilter,
) -> Result<(), Error> {
    tracing::info!(url = RIS_LIVE_URL, "connecting");
    let (mut ws_stream, _) = tokio_tungstenite::connect_async(RIS_LIVE_URL).await?;

    let peer = ws_stream.get_ref().get_ref().peer_addr()?;
    tracing::info!(remote_addr = ?peer, "successfully connected");

    let message = RisLiveClientMessage::RisSubscribe(filter);
    tracing::debug!(message = ?message, "sending subscribe message");
    let message = serde_json::to_string(&message)?.into();
    ws_stream.send(tungstenite::Message::Text(message)).await?;

    while let Some(Some(message)) = ws_stream.next().with_context(&ctx).await {
        match process_message(message, &mut ws_stream, &tx).await {
            Ok(false) => {}
            Ok(true) => {
                break;
            }
            Err(e) => {
                ws_stream
                    .close(Some(CloseFrame {
                        code: CloseCode::Error,
                        reason: "error handling connection".into(),
                    }))
                    .await?;
                return Err(e);
            }
        }
    }

    tracing::debug!("connection loop finished successfully, closing connection");
    ws_stream
        .close(Some(CloseFrame {
            code: CloseCode::Normal,
            reason: "connection is finished".into(),
        }))
        .await?;

    Ok(())
}

async fn process_message(
    message: tungstenite::Result<tungstenite::Message>,
    ws_stream: &mut WebSocketStream<MaybeTlsStream<TcpStream>>,
    tx: &tokio::sync::mpsc::Sender<protocol::RisLiveServerMessage>,
) -> Result<bool, Error> {
    let message = message?;

    if message.is_close() {
        tracing::debug!("received close message");
        return Ok(true);
    }

    if message.is_ping() {
        tracing::trace!("received ping message, sending pong");
        ws_stream
            .send(tungstenite::Message::Pong(message.into_data()))
            .await?;
        return Ok(false);
    }

    if message.is_text() {
        let message: protocol::RisLiveServerMessage = serde_json::from_slice(&message.into_data())?;
        tx.send(message).await?;
        return Ok(false);
    }

    Err(Error::InvalidMessage)
}
