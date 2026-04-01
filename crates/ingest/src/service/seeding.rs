use std::sync::Arc;

use anyhow::Context;
use chrono::NaiveDateTime;
use db::{
    self,
    batcher::{EventBatcher, RouteInsertBatcher, RoutesBatcher},
};

use crate::{
    bgp::{Event, EventType},
    global::Global,
    ripe_ris::{self, archived::file_names::next_update_date},
};

#[tracing::instrument(level = "info", skip_all)]
pub(crate) async fn seed(
    global: &Arc<Global>,
    ctx: &scuffle_context::Context,
    rrc: &str,
) -> anyhow::Result<()> {
    tracing::info!(path = ?global.config.cache_dir, "creating cache dir");
    tokio::fs::create_dir_all(&global.config.cache_dir)
        .await
        .context("failed to create cache dir")?;

    tracing::info!("starting to seed db");

    if let Some(updates_since) = db::last_route_timestamp(&global.db)
        .await?
        .map(|dt| dt.naive_utc())
    {
        process_updates(global, ctx, updates_since, rrc).await?;
    } else {
        tracing::info!("the routes table is empty");
        let bview_time = process_bview(global, ctx, rrc).await?;
        process_updates(global, ctx, bview_time, rrc).await?;
    }

    tracing::info!("seeding finished");

    Ok(())
}

async fn process_bview(
    global: &Arc<Global>,
    ctx: &scuffle_context::Context,
    rrc: &str,
) -> anyhow::Result<NaiveDateTime> {
    let host = format!("{rrc}.ripe.net");

    tracing::info!("starting to process bview");

    let bview_date = ripe_ris::archived::file_names::current_bview_date();
    let bview_file = ripe_ris::archived::download_file(
        ripe_ris::archived::file_names::bview_url(rrc, bview_date),
        &global.config.cache_dir,
    )
    .await?
    .context("bview file not found")?;

    let mut route_batcher = RouteInsertBatcher::new(global.db.clone());

    tracing::info!(file = ?bview_file, "parsing bview file");
    let parser = bgpkit_parser::BgpkitParser::new(&bview_file.display().to_string())
        .context("failed to create bgpkit parser")?;

    for elem in parser.into_elem_iter() {
        if ctx.is_done() {
            break;
        }

        match ripe_ris::archived::bgpkit_elem_into_event(elem, host.clone()).map(|e| e.normalize())
        {
            Ok(Some(Event {
                typ: EventType::Announcement(announcement),
                timestamp,
            })) => {
                route_batcher
                    .insert(announcement.into_route(timestamp))
                    .await?;
            }
            Ok(_) => {
                // ignore invalid events and withdrawals
            }
            Err(e) => {
                tracing::warn!(err = ?e, "failed to parse event");
            }
        }
    }

    route_batcher.finish().await?;

    Ok(bview_date)
}

async fn process_updates(
    global: &Arc<Global>,
    ctx: &scuffle_context::Context,
    since: NaiveDateTime,
    rrc: &str,
) -> anyhow::Result<()> {
    let host = format!("{rrc}.ripe.net");

    tracing::info!(since = ?since, "starting to process updates");

    let event_batcher = EventBatcher::new(&global.clickhouse, ctx.clone());
    let mut route_batcher = RoutesBatcher::new(global.db.clone(), ctx.clone());

    let mut current = since;

    while let Some(update_date) = next_update_date(current)
        && !ctx.is_done()
    {
        current = update_date;
        let url = ripe_ris::archived::file_names::update_url(rrc, update_date);
        let Some(file) = ripe_ris::archived::download_file(url, &global.config.cache_dir).await?
        else {
            tracing::warn!(update_date = ?update_date, "update file not found, skipping");
            continue;
        };

        tracing::info!(file = ?file, "parsing update file");
        let parser = bgpkit_parser::BgpkitParser::new(&file.display().to_string())
            .context("failed to create bgpkit parser")?;

        for elem in parser.into_elem_iter() {
            if ctx.is_done() {
                break;
            }

            let event = match ripe_ris::archived::bgpkit_elem_into_event(elem, host.clone())
                .map(|e| e.normalize())
            {
                Ok(Some(event)) => event,
                Ok(None) => continue,
                Err(e) => {
                    tracing::warn!(err = ?e, "failed to parse route");
                    continue;
                }
            };

            event_batcher.insert(&event.to_db()?).await?;

            match event.typ {
                EventType::Announcement(announcement) => {
                    route_batcher
                        .upsert(announcement.into_route(event.timestamp))
                        .await?;
                }
                EventType::Withdrawal(withdrawal) => {
                    route_batcher
                        .delete(withdrawal.prefix, withdrawal.peer_ip, withdrawal.host)
                        .await?;
                }
            }
        }
    }

    event_batcher.end().await?;
    route_batcher.end().await?;

    Ok(())
}
