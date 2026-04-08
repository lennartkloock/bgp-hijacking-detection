use std::{collections::HashSet, net::IpAddr};

use chrono::{DateTime, Utc};
use cidr::IpCidr;
use db::to_ipv6;

#[derive(Debug, Clone)]
pub struct Event {
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub typ: EventType,
}

impl Event {
    pub fn normalize(mut self) -> Option<Self> {
        match &mut self.typ {
            EventType::Announcement(announcement) => {
                if is_default_route(announcement.prefix) {
                    return None;
                }

                announcement.origin_asn.retain(|asn| !is_private_asn(*asn));
                if announcement.origin_asn.is_empty() {
                    return None;
                }
            }
            EventType::Withdrawal(withdrawal) => {
                if is_default_route(withdrawal.prefix) {
                    return None;
                }
            }
        }

        Some(self)
    }

    pub fn to_db(&self) -> db::Event {
        match &self.typ {
            EventType::Announcement(announcement) => db::Event {
                timestamp: self.timestamp,
                event_type: db::EventType::Announcement,
                prefix_addr: to_ipv6(announcement.prefix.first_address()),
                prefix_len: announcement.prefix.network_length(),
                origin_asn: announcement.origin_asn.iter().copied().collect(),
                peer_asn: announcement.peer_asn,
                peer_ip: to_ipv6(announcement.peer_ip),
                host: announcement.host,
                next_hop: announcement
                    .next_hop
                    .iter()
                    .map(|ip| to_ipv6(*ip))
                    .collect(),
            },
            EventType::Withdrawal(withdrawal) => db::Event {
                timestamp: self.timestamp,
                event_type: db::EventType::Withdrawal,
                prefix_addr: to_ipv6(withdrawal.prefix.first_address()),
                prefix_len: withdrawal.prefix.network_length(),
                origin_asn: vec![],
                peer_asn: withdrawal.peer_asn,
                peer_ip: to_ipv6(withdrawal.peer_ip),
                host: withdrawal.host,
                next_hop: vec![],
            },
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
    pub host: u8,
    pub as_path: serde_json::Value,
    pub next_hop: Vec<IpAddr>,
}

impl Announcement {
    pub fn into_route(self, timestamp: DateTime<Utc>) -> db::Route {
        db::Route {
            prefix: self.prefix,
            origin_asn: self.origin_asn.into_iter().map(|asn| asn as i64).collect(),
            peer_asn: self.peer_asn as i64,
            peer_ip: self.peer_ip,
            host: self.host as i16,
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
    pub host: u8,
}

pub fn is_default_route(prefix: IpCidr) -> bool {
    prefix.network_length() == 0
}

pub fn is_private_asn(asn: u32) -> bool {
    (64512..=65534).contains(&asn) || // RFC6996
        (4200000000..=4294967294).contains(&asn) // RFC6996
            || asn == 4294967295 // RFC7300
            || asn == 0 // RFC7607
}
