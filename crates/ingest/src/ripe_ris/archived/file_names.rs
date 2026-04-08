use chrono::{NaiveDateTime, TimeDelta, Timelike};
use reqwest::Url;

pub(crate) fn current_bview_date() -> NaiveDateTime {
    let now = chrono::Utc::now().naive_utc();
    now.with_hour((now.hour() / 8) * 8)
        .unwrap()
        .with_minute(0)
        .unwrap()
        .with_second(0)
        .unwrap()
        .with_nanosecond(0)
        .unwrap()
}

pub(crate) fn next_update_date(since: NaiveDateTime) -> Option<NaiveDateTime> {
    let now = chrono::Utc::now().naive_utc();

    let mut current = since
        .with_minute((since.minute() / 5) * 5)
        .unwrap()
        .with_second(0)
        .unwrap()
        .with_nanosecond(0)
        .unwrap();

    current = current.checked_add_signed(TimeDelta::minutes(5)).unwrap();

    if current < now { Some(current) } else { None }
}

pub(crate) fn bview_url(rrc: u8, date: NaiveDateTime) -> Url {
    let month = date.format("%Y.%m").to_string();
    let date_str = date.format("%Y%m%d.%H%M").to_string();

    format!("https://data.ris.ripe.net/rrc{rrc:02}/{month}/bview.{date_str}.gz")
        .parse()
        .unwrap()
}

pub(crate) fn update_url(rrc: u8, date: NaiveDateTime) -> Url {
    let month = date.format("%Y.%m").to_string();
    let date_str = date.format("%Y%m%d.%H%M").to_string();

    format!("https://data.ris.ripe.net/rrc{rrc:02}/{month}/updates.{date_str}.gz")
        .parse()
        .unwrap()
}
