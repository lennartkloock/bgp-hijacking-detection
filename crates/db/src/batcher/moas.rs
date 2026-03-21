use std::pin::pin;

use anyhow::Context;
use postgres_types::Type;
use tokio_postgres::binary_copy::BinaryCopyInWriter;

use crate::{DbPool, MoasPrefix};

const BATCH_SIZE: usize = 100;

pub struct MoasInsertBatcher {
    db: DbPool,
    batch: Vec<MoasPrefix>,
}

impl MoasInsertBatcher {
    pub fn new(db: DbPool) -> Self {
        Self {
            db,
            batch: Vec::with_capacity(BATCH_SIZE),
        }
    }

    pub async fn insert(&mut self, moas: MoasPrefix) -> anyhow::Result<Option<u64>> {
        self.batch.push(moas);

        if self.batch.len() < BATCH_SIZE {
            return Ok(None);
        }

        self.finish().await.map(Some)
    }

    pub async fn extend(&mut self, moases: Vec<MoasPrefix>) -> anyhow::Result<Option<u64>> {
        self.batch.reserve_exact(moases.len());
        self.batch.extend(moases);

        if self.batch.len() < BATCH_SIZE {
            return Ok(None);
        }

        self.finish().await.map(Some)
    }

    pub async fn finish(&mut self) -> anyhow::Result<u64> {
        let mut batch = Vec::with_capacity(BATCH_SIZE);
        std::mem::swap(&mut self.batch, &mut batch);

        let conn = self.db.get().await.context("failed to get connection")?;
        let sink = conn
            .copy_in("COPY moas (prefix, origins) FROM STDIN BINARY")
            .await
            .context("failed to open writer")?;
        let mut writer = pin!(BinaryCopyInWriter::new(
            sink,
            &[Type::CIDR, Type::INT8_ARRAY]
        ));

        for moas in batch {
            writer
                .as_mut()
                .write(&[&moas.prefix, &moas.origins])
                .await
                .context("failed to write row")?;
        }

        let rows = writer
            .finish()
            .await
            .context("failed to write batch to db")?;

        tracing::debug!(rows, "wrote moas batch to db");

        Ok(rows)
    }
}
