use anyhow::Context;

pub(crate) mod archived;
pub(crate) mod live;

pub(crate) fn timestamp_into_chrono(
    timestamp: f64,
) -> anyhow::Result<chrono::DateTime<chrono::Utc>> {
    chrono::DateTime::from_timestamp_millis((timestamp * 1000.0) as i64)
        .context("failed to convert timestamp")
}
