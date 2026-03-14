use anyhow::Context;

use crate::{DbPool, MoasPrefix};

const BATCH_SIZE: usize = 1000;

pub struct MoasFetcher {
    db: DbPool,
    prefixes: Vec<cidr::IpCidr>,
}

impl MoasFetcher {
    pub fn new(db: DbPool) -> Self {
        Self {
            db,
            prefixes: Vec::with_capacity(BATCH_SIZE),
        }
    }

    pub async fn fetch(&mut self, prefix: cidr::IpCidr) -> anyhow::Result<Option<Vec<MoasPrefix>>> {
        self.prefixes.push(prefix);

        if self.prefixes.len() < BATCH_SIZE {
            return Ok(None);
        }

        self.finish().await.map(Some)
    }

    pub async fn finish(&mut self) -> anyhow::Result<Vec<MoasPrefix>> {
        let mut prefixes = Vec::with_capacity(BATCH_SIZE);
        std::mem::swap(&mut self.prefixes, &mut prefixes);

        let conn = self.db.get().await.context("failed to get connection")?;
        let rows: Vec<_> = conn
            .query(
                "SELECT
                prefix,
                array_agg(DISTINCT origin) AS origins
            FROM routes,
                LATERAL UNNEST(origin_asn) AS origin
            WHERE prefix = ANY($1)
            GROUP BY prefix
            HAVING count(DISTINCT origin_asn) > 1
            ORDER BY count(DISTINCT origin) DESC;
            ",
                &[&prefixes],
            )
            .await
            .context("failed to query moas prefixes")?
            .into_iter()
            .map(MoasPrefix::from_row)
            .collect::<Result<_, _>>()
            .context("failed to convert into moas prefixes")?;

        tracing::debug!(rows = rows.len(), "fetched moas routes from db");

        Ok(rows)
    }
}
