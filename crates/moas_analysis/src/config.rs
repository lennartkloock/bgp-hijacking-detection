#[derive(Debug, serde::Deserialize)]
#[serde(default)]
pub struct Config {
    pub log_level: String,
    pub db_url: String,
    pub update_moas: bool,
    pub zmap_concurrency: usize,
    pub network_interface: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            log_level: "info,moas_analysis=debug".to_string(),
            db_url: "postgres://postgres:postgres@localhost/postgres".to_string(),
            update_moas: false,
            zmap_concurrency: 5,
            network_interface: "enp11s0".to_string(),
        }
    }
}

scuffle_settings::bootstrap!(Config);
