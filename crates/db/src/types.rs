use std::net::IpAddr;

#[derive(Debug, postgres_types::ToSql)]
#[postgres(name = "event_type", rename_all = "snake_case")]
pub enum EventType {
    Announcement,
    Withdrawal,
}

#[derive(Debug)]
pub struct NewEvent {
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub event_type: EventType,
    pub prefix: cidr::IpCidr,
    pub origin_asn: Option<Vec<i64>>,
    pub peer_asn: i64,
    pub peer_ip: IpAddr,
    pub host: String,
    pub next_hop: Option<Vec<IpAddr>>,
    pub as_path: Option<serde_json::Value>,
}

#[derive(Debug)]
pub struct Route {
    pub prefix: cidr::IpCidr,
    pub origin_asn: Vec<i64>,
    pub peer_asn: i64,
    pub peer_ip: IpAddr,
    pub host: String,
    pub as_path: serde_json::Value,
}

impl Route {
    pub fn to_tuple(&self) -> (cidr::IpCidr, &[i64], i64, IpAddr, &str, &serde_json::Value) {
        (
            self.prefix,
            &self.origin_asn,
            self.peer_asn,
            self.peer_ip,
            &self.host,
            &self.as_path,
        )
    }
}

#[derive(Debug)]
pub struct MoasPrefix {
    pub prefix: cidr::IpCidr,
    pub origins: Vec<i64>,
}

impl MoasPrefix {
    pub(crate) fn from_row(row: tokio_postgres::Row) -> Result<Self, tokio_postgres::Error> {
        Ok(Self {
            prefix: row.try_get("prefix")?,
            origins: row.try_get("origins")?,
        })
    }

    pub fn to_tuple(&self) -> (cidr::IpCidr, &[i64]) {
        (self.prefix, &self.origins)
    }
}
