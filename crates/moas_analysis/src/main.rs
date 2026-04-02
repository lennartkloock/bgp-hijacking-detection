use serde::Deserialize;

#[derive(serde::Deserialize)]
pub struct BgpToolsEntry {
    #[serde(deserialize_with = "deserialize_asn")]
    pub asn: u32,
    pub name: String,
}

fn deserialize_asn<'de, D: serde::Deserializer<'de>>(deserializer: D) -> Result<u32, D::Error> {
    let s = String::deserialize(deserializer)?;
    s.strip_prefix("AS")
        .ok_or(serde::de::Error::custom("missing AS prefix"))?
        .parse()
        .map_err(|e| serde::de::Error::custom(e))
}

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
    
    println!("querying moas prefixes...");
    let moas = pg_client
        .query(
            "SELECT prefix, array_agg(DISTINCT origin) AS origins
            FROM routes, LATERAL UNNEST(origin_asn) AS origin
            GROUP BY prefix
            HAVING count(DISTINCT origin) > 1",
            &[],
        )
        .await
        .unwrap();

    println!("found: {} moas prefixes", moas.len());

    // let moas: Vec<_> = moas
    //     .into_iter()
    //     .map(|row| MoasPrefix {
    //         prefix: row.get("prefix"),
    //         origins: row.get("origins"),
    //     })
    //     .filter(|m| {
    //         m.origins
    //             .iter()
    //             .all(|asn| !anycast_asn.contains(&(*asn as u32)))
    //     })
    //     .collect();

    println!("filtered: {} moas prefixes", moas.len());

    // for prefix in moas.iter().filter(|p| p.prefix.is_ipv4()) {
    //     println!("{}, {:?}", prefix.prefix, prefix.origins);
    // }
}
