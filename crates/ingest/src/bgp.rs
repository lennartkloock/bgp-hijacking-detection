use std::net::IpAddr;

#[derive(Debug, Clone)]
pub struct Event {
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub typ: EventType,
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

#[derive(Debug, Clone)]
pub struct Withdrawal {
    pub prefix: cidr::IpCidr,
    pub peer_asn: u32,
    pub peer_ip: IpAddr,
    pub host: String,
}
