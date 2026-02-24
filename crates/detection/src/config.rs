#[derive(Debug, serde::Deserialize)]
#[serde(default)]
pub struct Config {
    pub log_level: String,
    pub db_url: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            log_level: "info".to_string(),
            db_url: "postgres://postgres:postgres@localhost/".to_string(),
        }
    }
}

scuffle_settings::bootstrap!(Config);
