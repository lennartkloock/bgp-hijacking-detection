#[derive(Debug, serde::Deserialize)]
#[serde(default)]
pub struct Config {
    pub log_level: String,
    pub db_url: String,
    pub update_moas: bool,
    pub zmap_concurrency: usize,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            log_level: "info,moas_analysis=debug".to_string(),
            db_url: "postgres://postgres:postgres@localhost/postgres".to_string(),
            update_moas: false,
            zmap_concurrency: 5,
        }
    }
}

scuffle_settings::bootstrap!(Config);
