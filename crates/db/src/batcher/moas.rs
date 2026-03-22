use anyhow::Context;

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

        let (prefix, origins): (Vec<_>, Vec<&[i64]>) =
            itertools::multiunzip(batch.iter().map(MoasPrefix::to_tuple));

        let origin_asn_text: Vec<_> = origins
            .into_iter()
            .map(|origins| {
                origins
                    .iter()
                    .map(|asn| asn.to_string())
                    .collect::<Vec<_>>()
                    .join(",")
            })
            .collect();

        let rows = conn
            .execute(
                "INSERT INTO moas (prefix, origins)
            SELECT prefix, string_to_array(origin_asn_text, ',')::BIGINT[]
            FROM UNNEST($1::CIDR[], $2::TEXT[])
            AS t(prefix, origin_asn_text)
            ON CONFLICT (prefix) DO UPDATE SET
                origins = ARRAY(
                    SELECT DISTINCT UNNEST(moas.origins || EXCLUDED.origins)
                ),
                updated_at = NOW();",
                &[&prefix, &origin_asn_text],
            )
            .await
            .context("failed to upsert moas prefixes")?;

        tracing::debug!(rows, "wrote moas batch to db");

        Ok(rows)
    }
}
