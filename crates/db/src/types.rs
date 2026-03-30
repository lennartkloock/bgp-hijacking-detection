use std::{
    net::{IpAddr, Ipv6Addr},
    num::ParseIntError,
};

use chrono::{DateTime, Utc};

pub fn to_ipv6(ip: IpAddr) -> Ipv6Addr {
    match ip {
        IpAddr::V4(v4) => v4.to_ipv6_mapped(),
        IpAddr::V6(v6) => v6,
    }
}

pub fn parse_rrc(rrc: &str) -> Result<u8, ParseIntError> {
    rrc.trim_end_matches(".ripe.net")
        .trim_start_matches("rrc")
        .parse()
}

#[derive(Debug, serde_repr::Serialize_repr)]
#[repr(i8)]
pub enum EventType {
    Announcement = 1,
    Withdrawal = 2,
}

#[derive(Debug, clickhouse::Row, serde::Serialize)]
pub struct Event {
    #[serde(with = "clickhouse::serde::chrono::datetime64::millis")]
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub event_type: EventType,
    pub prefix_addr: Ipv6Addr,
    pub prefix_len: u8,
    pub origin_asn: Vec<u32>,
    pub peer_asn: u32,
    pub peer_ip: Ipv6Addr,
    pub host: u8,
    pub next_hop: Vec<Ipv6Addr>,
}

#[derive(Debug)]
pub struct Route {
    pub prefix: cidr::IpCidr,
    pub origin_asn: Vec<i64>,
    pub peer_asn: i64,
    pub peer_ip: IpAddr,
    pub host: String,
    pub as_path: serde_json::Value,
    pub updated_at: DateTime<Utc>,
}

impl Route {
    pub fn to_tuple(
        &self,
    ) -> (
        cidr::IpCidr,
        &[i64],
        i64,
        IpAddr,
        &str,
        &serde_json::Value,
        DateTime<Utc>,
    ) {
        (
            self.prefix,
            &self.origin_asn,
            self.peer_asn,
            self.peer_ip,
            &self.host,
            &self.as_path,
            self.updated_at,
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
