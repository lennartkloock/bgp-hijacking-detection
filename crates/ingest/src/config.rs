use std::{path::PathBuf, str::FromStr};

#[derive(Debug, serde::Deserialize)]
#[serde(default)]
pub struct Config {
    pub log_level: String,
    pub db_url: String,
    pub only_seed: bool,
    pub seed_rrc: String,
    pub cache_dir: PathBuf,
    pub insert_events: bool,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            log_level: "info".to_string(),
            db_url: "postgres://postgres:postgres@localhost/postgres".to_string(),
            only_seed: false,
            seed_rrc: "rrc12".to_string(),
            cache_dir: PathBuf::from_str("local").unwrap().join("cache"),
            insert_events: true,
        }
    }
}

scuffle_settings::bootstrap!(Config);
