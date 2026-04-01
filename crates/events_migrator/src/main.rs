use std::{net::IpAddr, pin::pin};

use db::Event;
use futures_util::TryStreamExt;
use tokio_postgres::{binary_copy::BinaryCopyOutStream, types::Type};

#[derive(Debug, postgres_types::FromSql)]
#[postgres(name = "event_type", rename_all = "snake_case")]
pub enum EventType {
    Announcement,
    Withdrawal,
}

impl From<EventType> for db::EventType {
    fn from(value: EventType) -> Self {
        match value {
            EventType::Announcement => Self::Announcement,
            EventType::Withdrawal => Self::Withdrawal,
        }
    }
}

const EVENTS_SIZE: u64 = 1_813_009_408;

#[tokio::main]
async fn main() {
    println!("connecting to postgres");
    let (pg_client, pg_conn) =
        db::connect_raw("postgres://postgres:postgres@localhost:5432/postgres")
            .await
            .unwrap();

    tokio::spawn(async move {
        if let Err(e) = pg_conn.await {
            eprintln!("connection error: {}", e);
        }
    });

    println!("connected to postgres");

    let event_type_pg = {
        let row = pg_client
            .query_one("SELECT NULL::event_type", &[])
            .await
            .unwrap();
        row.columns()[0].type_().clone()
    };
    println!("queried event_type");

    let stream = pg_client
        .copy_out("COPY events TO STDOUT BINARY")
        .await
        .unwrap();
    let mut stream = pin!(BinaryCopyOutStream::new(
        stream,
        &[
            Type::INT8,
            Type::TIMESTAMPTZ,
            event_type_pg,
            Type::CIDR,
            Type::INT8_ARRAY,
            Type::INT8,
            Type::INET,
            Type::VARCHAR,
            Type::INET_ARRAY,
        ]
    ));

    println!("connecting to clickhouse");
    let ch_client = clickhouse::Client::default()
        .with_url("http://localhost:8123")
        .with_user("default")
        .with_password("default")
        .with_database("default");
    let mut inserter = ch_client
        .inserter::<db::Event>("events")
        .with_max_rows(500_000);
    println!("connected to clickhouse");

    let progress = indicatif::ProgressBar::new(EVENTS_SIZE);
    progress.set_style(
        indicatif::ProgressStyle::with_template(
            "{wide_bar} {human_pos}/{human_len} ({eta_precise})",
        )
        .unwrap(),
    );

    while let Some(old_event) = stream.try_next().await.unwrap() {
        let timestamp = old_event.get(1);
        let event_type: EventType = old_event.get(2);
        let prefix: cidr::IpCidr = old_event.get(3);
        let origin_asn: Option<Vec<i64>> = old_event.get(4);
        let peer_asn: i64 = old_event.get(5);
        let peer_ip: IpAddr = old_event.get(6);
        let host: String = old_event.get(7);
        let next_hop: Option<Vec<IpAddr>> = old_event.get(8);

        inserter
            .write(&Event {
                timestamp,
                event_type: event_type.into(),
                prefix_addr: db::to_ipv6(prefix.first_address()),
                prefix_len: prefix.network_length(),
                origin_asn: origin_asn
                    .map(|v| v.into_iter().map(|asn| asn as u32).collect())
                    .unwrap_or_default(),
                peer_asn: peer_asn as u32,
                peer_ip: db::to_ipv6(peer_ip),
                host: db::parse_rrc(&host).unwrap(),
                next_hop: next_hop
                    .map(|v| v.into_iter().map(db::to_ipv6).collect())
                    .unwrap_or_default(),
            })
            .await
            .unwrap();

        let n = inserter.commit().await.unwrap();
        if n.rows > 0 {
            progress.inc(n.rows);
        }
    }

    inserter.end().await.unwrap();
    progress.finish();
}
