use std::net::SocketAddr;

#[derive(Debug, serde::Deserialize)]
#[serde(default)]
pub struct Config {
    pub log_level: String,
    pub db_url: String,
    pub pprof_bind: Option<SocketAddr>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            log_level: "info".to_string(),
            db_url: "postgres://postgres:postgres@localhost/postgres".to_string(),
            pprof_bind: None,
        }
    }
}

scuffle_settings::bootstrap!(Config);
