use std::sync::Arc;

use anyhow::Context;
use db::{
    Event, EventType, Route, batcher::RoutesBatcher, clickhouse_inserter_commit, parse_rrc, to_ipv6,
};
use tokio::sync::Mutex;

use crate::{
    global::Global,
    ripe_ris::{
        live::protocol::{AsPathElement, RisLiveServerMessage, RisMessageType},
        timestamp_into_chrono,
    },
};

pub(crate) async fn handle_message(
    _global: &Arc<Global>,
    event_inserter: &Arc<Mutex<clickhouse::inserter::Inserter<Event>>>,
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
            let peer_v6 = to_ipv6(peer);
            let host_u8 = parse_rrc(&host).context("failed to parse rrc")?;

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

                    let origin_asn = origin_asn.to_vec();
                    let origin_asn_64: Vec<_> = origin_asn.iter().map(|asn| *asn as i64).collect();

                    for announcement in announcements.iter() {
                        let next_hop_v6: Vec<_> = announcement
                            .next_hop
                            .iter()
                            .map(|ip| to_ipv6(*ip))
                            .collect();

                        for prefix in announcement.prefixes.iter() {
                            event_inserter
                                .lock()
                                .await
                                .write(&Event {
                                    timestamp,
                                    event_type: EventType::Announcement,
                                    prefix_addr: to_ipv6(prefix.first_address()),
                                    prefix_len: prefix.network_length(),
                                    origin_asn: origin_asn.clone(),
                                    peer_asn,
                                    peer_ip: peer_v6,
                                    host: host_u8,
                                    next_hop: next_hop_v6.clone(),
                                })
                                .await
                                .context("failed to write event")?;

                            route_batcher
                                .upsert(Route {
                                    prefix: *prefix,
                                    origin_asn: origin_asn_64.clone(),
                                    peer_asn: peer_asn as i64,
                                    peer_ip: peer,
                                    host: host.clone(),
                                    as_path: as_path.clone(),
                                    updated_at: timestamp,
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
                    event_inserter
                        .lock()
                        .await
                        .write(&Event {
                            timestamp,
                            event_type: EventType::Withdrawal,
                            prefix_addr: to_ipv6(prefix.first_address()),
                            prefix_len: prefix.network_length(),
                            origin_asn: vec![],
                            peer_asn,
                            peer_ip: to_ipv6(peer),
                            host: host_u8,
                            next_hop: vec![],
                        })
                        .await
                        .context("failed to write event")?;

                    route_batcher
                        .delete(prefix, peer, host.clone())
                        .await
                        .context("failed to delete route")?;
                }
            }
        }
        _ => {}
    }

    clickhouse_inserter_commit(&mut *event_inserter.lock().await).await?;

    Ok(())
}
