use std::sync::Arc;

use anyhow::Context;

use crate::{
    global::Global,
    ripe_ris::live::protocol::{AsPathElement, RisLiveServerMessage, RisMessageType},
    service::batcher::PrefixInsertBatcher,
};

pub(crate) async fn handle_message(
    global: &Arc<Global>,
    batcher: &mut PrefixInsertBatcher,
    message: RisLiveServerMessage,
) -> anyhow::Result<()> {
    match message {
        RisLiveServerMessage::RisError { message } => {
            tracing::error!(message = message, "RIS error")
        }
        RisLiveServerMessage::RisMessage {
            typ:
                RisMessageType::Update {
                    announcements,
                    withdrawals,
                    path: Some(path),
                    ..
                },
            ..
        } => {
            if let Some(AsPathElement::Asn(origin_asn)) = path.last() {
                let origin_asn = *origin_asn as i64;

                if let Some(announcements) = announcements {
                    for announcement in announcements {
                        for prefix in announcement.prefixes {
                            if let Some(rows) = batcher
                                .insert((prefix, origin_asn))
                                .await
                                .context("failed to insert prefix")?
                            {
                                tracing::info!(rows = rows, "wrote batch to db");
                            }
                        }
                    }
                }

                if let Some(withdrawals) = withdrawals {
                    for prefix in withdrawals {
                        sqlx::query!(
                            "UPDATE prefixes SET withdrawn_at = NOW() WHERE prefix = $1 AND origin_asn = $2",
                            prefix,
                            origin_asn,
                        )
                        .execute(&global.db)
                        .await
                        .context("failed to withdraw prefix")?;

                        tracing::info!(prefix = %prefix, origin_asn = origin_asn, "withdrawn prefix");
                    }
                }
            }
        }
        _ => {}
    }

    Ok(())
}
