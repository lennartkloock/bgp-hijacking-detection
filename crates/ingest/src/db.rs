use std::net::IpAddr;

use anyhow::Context;

use crate::bgp;

pub(crate) mod batcher;

pub type DbPool = bb8::Pool<bb8_postgres::PostgresConnectionManager<tokio_postgres::NoTls>>;

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

impl From<bgp::Event> for NewEvent {
    fn from(value: bgp::Event) -> Self {
        match value.typ {
            bgp::EventType::Announcement(announcement) => Self {
                timestamp: value.timestamp,
                event_type: EventType::Announcement,
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
            bgp::EventType::Withdrawal(withdrawal) => Self {
                timestamp: value.timestamp,
                event_type: EventType::Withdrawal,
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

#[derive(Debug)]
pub struct Route {
    pub prefix: cidr::IpCidr,
    pub origin_asn: Vec<i64>,
    pub peer_asn: i64,
    pub peer_ip: IpAddr,
    pub host: String,
    pub as_path: serde_json::Value,
}

impl From<bgp::Announcement> for Route {
    fn from(value: bgp::Announcement) -> Self {
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
