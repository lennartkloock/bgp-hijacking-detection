use std::{path::PathBuf, str::FromStr};

#[derive(Debug, serde::Deserialize)]
#[serde(default)]
pub struct Config {
    pub log_level: String,
    pub db_url: String,
    pub clickhouse: ClickhouseConfig,
    pub only_seed: bool,
    pub seed_rrc: String,
    pub cache_dir: PathBuf,
    pub rrc_filter: Option<u8>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            log_level: "info".to_string(),
            db_url: "postgres://postgres:postgres@localhost/postgres".to_string(),
            clickhouse: ClickhouseConfig::default(),
            only_seed: false,
            seed_rrc: "rrc12".to_string(),
            cache_dir: PathBuf::from_str("local").unwrap().join("cache"),
            rrc_filter: None,
        }
    }
}

scuffle_settings::bootstrap!(Config);

#[derive(Debug, serde::Deserialize)]
#[serde(default)]
pub struct ClickhouseConfig {
    pub url: String,
    pub db: String,
    pub user: String,
    pub password: String,
}

impl Default for ClickhouseConfig {
    fn default() -> Self {
        Self {
            url: "http://localhost:8123".to_string(),
            db: "default".to_string(),
            user: "default".to_string(),
            password: "default".to_string(),
        }
    }
}
