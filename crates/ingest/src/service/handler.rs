use std::sync::Arc;

use anyhow::Context;

use crate::{
    db::{
        EventType, NewEvent, Route,
        batcher::{EventInsertBatcher, RoutesBatcher},
    },
    global::Global,
    ripe_ris::{
        live::protocol::{AsPathElement, RisLiveServerMessage, RisMessageType},
        timestamp_into_chrono,
    },
};

pub(crate) async fn handle_message(
    _global: &Arc<Global>,
    event_batcher: &mut EventInsertBatcher,
    route_batcher: &mut RoutesBatcher,
    message: RisLiveServerMessage,
) -> anyhow::Result<()> {
    match message {
        RisLiveServerMessage::RisError { message } => {
            tracing::error!(message = message, "RIS error")
        }
        RisLiveServerMessage::RisMessage {
            timestamp,
            host,
            peer_asn,
            peer,
            typ:
                RisMessageType::Update {
                    announcements,
                    withdrawals,
                    path: Some(path),
                    ..
                },
            ..
        } => {
            let timestamp = timestamp_into_chrono(timestamp)?;

            // Insert all announcements
            if let Some(announcements) = announcements
                && !announcements.is_empty()
            {
                // ignore empty paths
                if let Some(origin_asn) = path.last() {
                    let as_path: Vec<_> = path
                        .iter()
                        .map(|pe| match pe {
                            AsPathElement::Asn(asn) => serde_json::Value::from(*asn),
                            AsPathElement::AsSet(set) => serde_json::Value::Array(
                                set.iter()
                                    .map(|asn| serde_json::Value::from(*asn))
                                    .collect(),
                            ),
                        })
                        .collect();
                    let as_path = serde_json::Value::Array(as_path);

                    let origin_asn: Vec<_> = origin_asn
                        .to_vec()
                        .into_iter()
                        .map(|asn| asn as i64)
                        .collect();

                    for announcement in announcements.iter() {
                        for prefix in announcement.prefixes.iter() {
                            let prefix = *prefix;
                            let peer_asn = peer_asn as i64;

                            event_batcher
                                .insert(NewEvent {
                                    timestamp,
                                    event_type: EventType::Announcement,
                                    prefix,
                                    origin_asn: Some(origin_asn.clone()),
                                    peer_asn,
                                    peer_ip: peer,
                                    host: host.clone(),
                                    next_hop: Some(announcement.next_hop.clone()),
                                    as_path: Some(as_path.clone()),
                                })
                                .await
                                .context("failed to insert event")?;

                            route_batcher
                                .upsert(Route {
                                    prefix,
                                    origin_asn: origin_asn.clone(),
                                    peer_asn,
                                    peer_ip: peer,
                                    host: host.clone(),
                                    as_path: as_path.clone(),
                                })
                                .await
                                .context("failed to upsert route")?;
                        }
                    }
                } else {
                    tracing::error!(announcements = ?announcements, "path was emtpy");
                }
            }

            // Insert all withdrawals
            if let Some(withdrawals) = withdrawals {
                for prefix in withdrawals {
                    event_batcher
                        .insert(NewEvent {
                            timestamp,
                            event_type: EventType::Withdrawal,
                            prefix,
                            origin_asn: None,
                            peer_asn: peer_asn as i64,
                            peer_ip: peer,
                            host: host.clone(),
                            next_hop: None,
                            as_path: None,
                        })
                        .await
                        .context("failed to insert event")?;

                    route_batcher
                        .delete(prefix, peer, host.clone())
                        .await
                        .context("failed to delete route")?;
                }
            }
        }
        _ => {}
    }

    Ok(())
}
