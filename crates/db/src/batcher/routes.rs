use std::{net::IpAddr, pin::pin};

use anyhow::Context;
use cidr::IpCidr;
use fxhash::{FxBuildHasher, FxHashMap};
use tokio_postgres::{binary_copy::BinaryCopyInWriter, types::Type};

use crate::{DbPool, MoasPrefix, Route};

const COPY_BATCH_SIZE: usize = 10000;
const BATCH_SIZE: usize = 1000;

#[derive(Debug)]
enum RouteOperation {
    Upsert(Route),
    Delete,
}

pub struct RoutesBatcher {
    db: DbPool,
    operations: FxHashMap<(cidr::IpCidr, IpAddr, String), RouteOperation>,
}

impl RoutesBatcher {
    pub fn new(db: DbPool) -> Self {
        Self {
            db,
            operations: FxHashMap::with_capacity_and_hasher(1000, FxBuildHasher::new()),
        }
    }

    pub async fn upsert(&mut self, route: Route) -> anyhow::Result<Option<u64>> {
        let k = (route.prefix, route.peer_ip, route.host.clone());
        self.operations.insert(k, RouteOperation::Upsert(route));

        if self.operations.len() < BATCH_SIZE {
            return Ok(None);
        }

        self.finish().await.map(Some)
    }

    pub async fn delete(
        &mut self,
        prefix: IpCidr,
        peer_ip: IpAddr,
        host: String,
    ) -> anyhow::Result<Option<u64>> {
        self.operations
            .insert((prefix, peer_ip, host), RouteOperation::Delete);

        if self.operations.len() < BATCH_SIZE {
            return Ok(None);
        }

        self.finish().await.map(Some)
    }

    pub async fn finish(&mut self) -> anyhow::Result<u64> {
        let conn = self
            .db
            .get()
            .await
            .context("failed to connect get db connection")?;

        let mut operations = FxHashMap::with_capacity_and_hasher(1000, FxBuildHasher::new());
        std::mem::swap(&mut self.operations, &mut operations);

        let mut rows = 0;

        // Upserts
        {
            let (prefix, origin_asn, peer_asn, peer_ip, host, as_path): (
                Vec<_>,
                Vec<&[i64]>,
                Vec<_>,
                Vec<_>,
                Vec<_>,
                Vec<_>,
            ) = itertools::multiunzip(
                operations
                    .iter()
                    .filter_map(|(_, v)| match v {
                        RouteOperation::Upsert(r) => Some(r),
                        RouteOperation::Delete => None,
                    })
                    .map(Route::to_tuple),
            );

            let origin_asn_text: Vec<_> = origin_asn
                .into_iter()
                .map(|origins| {
                    origins
                        .iter()
                        .map(|asn| asn.to_string())
                        .collect::<Vec<_>>()
                        .join(",")
                })
                .collect();

            rows += conn
                .execute(
                    "WITH upserted AS (
                        INSERT INTO routes (prefix, origin_asn, peer_asn, peer_ip, host, as_path)
                        SELECT prefix, string_to_array(origin_asn_text, ',')::BIGINT[], peer_asn, peer_ip, host, as_path
                        FROM UNNEST($1::CIDR[], $2::TEXT[], $3::BIGINT[], $4::INET[], $5::VARCHAR[], $6::JSONB[])
                        AS t(prefix, origin_asn_text, peer_asn, peer_ip, host, as_path)
                        ON CONFLICT (prefix, peer_ip, host) DO UPDATE SET
                            origin_asn = EXCLUDED.origin_asn,
                            peer_asn = EXCLUDED.peer_asn,
                            as_path = EXCLUDED.as_path
                        RETURNING prefix
                    )
                    SELECT pg_notify('bgp_updates', prefix::TEXT)
                    FROM (SELECT DISTINCT prefix FROM upserted) AS changed;",
                    &[&prefix, &origin_asn_text, &peer_asn, &peer_ip, &host, &as_path],
                )
                .await
                .context("failed to upsert routes")?;
        }

        // Deletions
        {
            let (prefix, peer_ip, host): (Vec<&IpCidr>, Vec<&IpAddr>, Vec<&str>) =
                itertools::multiunzip(
                    operations
                        .iter()
                        .filter_map(|(k, v)| match v {
                            RouteOperation::Upsert(_) => None,
                            RouteOperation::Delete => Some(k),
                        })
                        .map(|(p, i, h)| (p, i, h.as_str())),
                );

            rows += conn
                .execute(
                    "DELETE FROM routes
                WHERE (prefix, peer_ip, host) in (
                    SELECT * FROM UNNEST($1::CIDR[], $2::INET[], $3::VARCHAR[])
                )",
                    &[&prefix, &peer_ip, &host],
                )
                .await
                .context("failed to delete routes")?;
        }

        tracing::debug!(rows, "wrote route batch to db");

        Ok(rows)
    }
}

pub struct RouteInsertBatcher {
    db: DbPool,
    batch: Vec<Route>,
}

impl RouteInsertBatcher {
    pub fn new(db: DbPool) -> Self {
        Self {
            db,
            batch: Vec::with_capacity(COPY_BATCH_SIZE),
        }
    }

    pub async fn insert(&mut self, route: Route) -> anyhow::Result<Option<u64>> {
        self.batch.push(route);

        if self.batch.len() < COPY_BATCH_SIZE {
            return Ok(None);
        }

        self.finish().await.map(Some)
    }

    pub async fn finish(&mut self) -> anyhow::Result<u64> {
        let mut batch = Vec::with_capacity(COPY_BATCH_SIZE);
        std::mem::swap(&mut self.batch, &mut batch);

        let conn = self.db.get().await.context("failed to get connection")?;
        // We don't NOTIFY for each prefix here because we can only detect hijackings live.
        let sink = conn.copy_in("COPY routes (prefix, origin_asn, peer_asn, peer_ip, host, as_path) FROM STDIN BINARY")
            .await
            .context("failed to open writer")?;
        let mut writer = pin!(BinaryCopyInWriter::new(
            sink,
            &[
                Type::CIDR,
                Type::INT8_ARRAY,
                Type::INT8,
                Type::INET,
                Type::VARCHAR,
                Type::JSONB
            ]
        ));

        for event in batch {
            writer
                .as_mut()
                .write(&[
                    &event.prefix,
                    &event.origin_asn,
                    &event.peer_asn,
                    &event.peer_ip,
                    &event.host,
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

pub struct MoasRoutesFetcher {
    db: DbPool,
    prefixes: Vec<cidr::IpCidr>,
}

impl MoasRoutesFetcher {
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
            WHERE prefix = ANY($1::CIDR[])
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
