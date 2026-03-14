use std::net::IpAddr;

#[derive(Debug, Clone)]
pub struct Event {
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub typ: EventType,
}

impl From<Event> for db::NewEvent {
    fn from(value: Event) -> Self {
        match value.typ {
            EventType::Announcement(announcement) => Self {
                timestamp: value.timestamp,
                event_type: db::EventType::Announcement,
                prefix: announcement.prefix,
                origin_asn: Some(
                    announcement
                        .origin_asn
                        .into_iter()
                        .map(|asn| asn as i64)
                        .collect(),
                ),
                peer_asn: announcement.peer_asn as i64,
                peer_ip: announcement.peer_ip,
                host: announcement.host,
                next_hop: Some(announcement.next_hop),
                as_path: Some(announcement.as_path),
            },
            EventType::Withdrawal(withdrawal) => Self {
                timestamp: value.timestamp,
                event_type: db::EventType::Withdrawal,
                prefix: withdrawal.prefix,
                origin_asn: None,
                peer_asn: withdrawal.peer_asn as i64,
                peer_ip: withdrawal.peer_ip,
                host: withdrawal.host,
                next_hop: None,
                as_path: None,
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
    pub origin_asn: Vec<u32>,
    pub peer_asn: u32,
    pub peer_ip: IpAddr,
    pub host: String,
    pub next_hop: Vec<IpAddr>,
    pub as_path: serde_json::Value,
}

impl From<Announcement> for db::Route {
    fn from(value: Announcement) -> Self {
        Self {
            prefix: value.prefix,
            origin_asn: value.origin_asn.into_iter().map(|asn| asn as i64).collect(),
            peer_asn: value.peer_asn as i64,
            peer_ip: value.peer_ip,
            host: value.host,
            as_path: value.as_path,
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
