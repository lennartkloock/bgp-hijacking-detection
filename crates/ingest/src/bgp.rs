use std::{collections::HashSet, net::IpAddr};

use anyhow::Context;
use chrono::{DateTime, Utc};
use db::{parse_rrc, to_ipv6};

#[derive(Debug, Clone)]
pub struct Event {
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub typ: EventType,
}

impl Event {
    pub fn to_db(&self) -> anyhow::Result<db::Event> {
        match &self.typ {
            EventType::Announcement(announcement) => Ok(db::Event {
                timestamp: self.timestamp,
                event_type: db::EventType::Announcement,
                prefix_addr: to_ipv6(announcement.prefix.first_address()),
                prefix_len: announcement.prefix.network_length(),
                origin_asn: announcement.origin_asn.iter().copied().collect(),
                peer_asn: announcement.peer_asn,
                peer_ip: to_ipv6(announcement.peer_ip),
                host: parse_rrc(&announcement.host).context("failed to parse host as rrc")?,
                next_hop: announcement
                    .next_hop
                    .iter()
                    .map(|ip| to_ipv6(*ip))
                    .collect(),
            }),
            EventType::Withdrawal(withdrawal) => Ok(db::Event {
                timestamp: self.timestamp,
                event_type: db::EventType::Withdrawal,
                prefix_addr: to_ipv6(withdrawal.prefix.first_address()),
                prefix_len: withdrawal.prefix.network_length(),
                origin_asn: vec![],
                peer_asn: withdrawal.peer_asn,
                peer_ip: to_ipv6(withdrawal.peer_ip),
                host: parse_rrc(&withdrawal.host).context("failed to parse host as rrc")?,
                next_hop: vec![],
            }),
        }
    }
}

#[derive(Debug, Clone)]
pub enum EventType {
    Announcement(Announcement),
    Withdrawal(Withdrawal),
}

#[derive(Debug, Clone)]
pub struct Announcement {
    pub prefix: cidr::IpCidr,
    pub origin_asn: HashSet<u32>,
    pub peer_asn: u32,
    pub peer_ip: IpAddr,
    pub host: String,
    pub next_hop: Vec<IpAddr>,
    pub as_path: serde_json::Value,
}

impl Announcement {
    pub fn into_route(self, timestamp: DateTime<Utc>) -> db::Route {
        db::Route {
            prefix: self.prefix,
            origin_asn: self.origin_asn.into_iter().map(|asn| asn as i64).collect(),
            peer_asn: self.peer_asn as i64,
            peer_ip: self.peer_ip,
            host: self.host,
            as_path: self.as_path,
            updated_at: timestamp,
        }
    }
}

#[derive(Debug, Clone)]
pub struct Withdrawal {
    pub prefix: cidr::IpCidr,
    pub peer_asn: u32,
    pub peer_ip: IpAddr,
    pub host: String,
}
