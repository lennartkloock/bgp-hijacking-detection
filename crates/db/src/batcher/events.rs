use std::pin::pin;

use anyhow::Context;
use tokio_postgres::{binary_copy::BinaryCopyInWriter, types::Type};

use crate::{DbPool, NewEvent};

const BATCH_SIZE: usize = 10000;

pub struct EventInsertBatcher {
    db: DbPool,
    batch: Vec<NewEvent>,
    event_type_pg: Type,
}

impl EventInsertBatcher {
    pub async fn new(db: DbPool) -> anyhow::Result<Self> {
        let event_type_pg = {
            let row = db
                .get()
                .await
                .context("failed to connect to db")?
                .query_one("SELECT NULL::event_type", &[])
                .await?;
            row.columns()[0].type_().clone()
        };

        Ok(Self {
            db,
            batch: Vec::with_capacity(BATCH_SIZE),
            event_type_pg,
        })
    }

    pub async fn insert(&mut self, event: NewEvent) -> anyhow::Result<Option<u64>> {
        self.batch.push(event);

        if self.batch.len() < BATCH_SIZE {
            return Ok(None);
        }

        self.finish().await.map(Some)
    }

    pub async fn finish(&mut self) -> anyhow::Result<u64> {
        let mut batch = Vec::with_capacity(BATCH_SIZE);
        std::mem::swap(&mut self.batch, &mut batch);

        let conn = self.db.get().await.context("failed to get connection")?;
        let sink = conn.copy_in("COPY events (timestamp, event_type, prefix, origin_asn, peer_asn, peer_ip, host, next_hop, as_path) FROM STDIN BINARY")
            .await
            .context("failed to open writer")?;
        let mut writer = pin!(BinaryCopyInWriter::new(
            sink,
            &[
                Type::TIMESTAMPTZ,
                self.event_type_pg.clone(),
                Type::CIDR,
                Type::INT8_ARRAY,
                Type::INT8,
                Type::INET,
                Type::VARCHAR,
                Type::INET_ARRAY,
                Type::JSONB
            ]
        ));

        for event in batch {
            writer
                .as_mut()
                .write(&[
                    &event.timestamp,
                    &event.event_type,
                    &event.prefix,
                    &event.origin_asn,
                    &event.peer_asn,
                    &event.peer_ip,
                    &event.host,
                    &event.next_hop,
                    &event.as_path,
                ])
                .await
                .context("failed to write row")?;
        }

        let rows = writer
            .finish()
            .await
            .context("failed to write batch to db")?;

        tracing::debug!(rows, "wrote route batch to db");

        Ok(rows)
    }
}
