use ipnetwork::IpNetwork;

pub(crate) struct PrefixInsertBatcher {
    db: sqlx::PgPool,
    batch: Vec<(IpNetwork, i64)>,
}

impl PrefixInsertBatcher {
    pub(crate) fn new(db: sqlx::PgPool) -> Self {
        Self {
            db,
            batch: Vec::new(),
        }
    }

    pub(crate) async fn insert(
        &mut self,
        prefix: (IpNetwork, i64),
    ) -> sqlx::Result<Option<u64>> {
        self.batch.push(prefix);

        if self.batch.len() < 1000 {
            return Ok(None);
        }

        let mut batch = Vec::new();
        std::mem::swap(&mut self.batch, &mut batch);
        let (prefixes, origin_asn): (Vec<_>, Vec<_>) = batch.into_iter().unzip();

        let res = sqlx::query!(
            "INSERT INTO prefixes (prefix, origin_asn)
            SELECT * FROM UNNEST($1::CIDR[], $2::BIGINT[])
            ON CONFLICT DO NOTHING",
            &prefixes,
            &origin_asn,
        )
        .execute(&self.db)
        .await?;

        Ok(Some(res.rows_affected()))
    }
}

pub(crate) struct PrefixWithdrawBatcher {
    db: sqlx::PgPool,
    batch: Vec<(IpNetwork, i64)>,
}

impl PrefixInsertBatcher {
    pub(crate) fn new(db: sqlx::PgPool) -> Self {
        Self {
            db,
            batch: Vec::new(),
        }
    }

    pub(crate) async fn insert(
        &mut self,
        prefix: (IpNetwork, i64),
    ) -> sqlx::Result<Option<u64>> {
        self.batch.push(prefix);

        if self.batch.len() < 1000 {
            return Ok(None);
        }

        let mut batch = Vec::new();
        std::mem::swap(&mut self.batch, &mut batch);
        let (prefixes, origin_asn): (Vec<_>, Vec<_>) = batch.into_iter().unzip();

        let res = sqlx::query!(
            "INSERT INTO prefixes (prefix, origin_asn)
            SELECT * FROM UNNEST($1::CIDR[], $2::BIGINT[])
            ON CONFLICT DO NOTHING",
            &prefixes,
            &origin_asn,
        )
        .execute(&self.db)
        .await?;

        Ok(Some(res.rows_affected()))
    }
}
