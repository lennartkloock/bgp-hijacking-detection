use std::path::{Path, PathBuf};

use anyhow::Context;
use cidr::IpCidr;
use futures_util::StreamExt;
use reqwest::{StatusCode, Url};
use tokio::{fs::File, io::AsyncWriteExt};

use crate::{
    bgp::{Announcement, Event, EventType, Withdrawal},
    ripe_ris::timestamp_into_chrono,
};

pub(crate) mod file_names;

pub(crate) async fn download_file(url: Url, cache_dir: &Path) -> anyhow::Result<Option<PathBuf>> {
    let file_path = cache_dir.join(url.path().trim_start_matches('/'));

    if file_path.exists() {
        tracing::debug!(file_path = ?file_path, "file already exists, skipping download");
        return Ok(Some(file_path));
    }

    if let Some(parent) = file_path.parent() {
        tokio::fs::create_dir_all(parent)
            .await
            .context("failed to create cache file directory")?;
    }

    let resp = reqwest::get(url)
        .await
        .context("failed to fetch latest bview")?;

    if resp.status() == StatusCode::NOT_FOUND {
        return Ok(None);
    }

    let resp = resp.error_for_status().context("unexpected response")?;

    let total_size = resp.content_length().context("missing content length")?;
    tracing::info!(file = ?file_path, total_size, "downloading file");

    let mut current = 0;
    let progress = indicatif::ProgressBar::new(total_size);
    progress.set_style(
        indicatif::ProgressStyle::with_template("{msg} [{wide_bar}] {bytes}/{total_bytes} ({eta})")
            .unwrap()
            .progress_chars("#--"),
    );

    progress.set_message(file_path.display().to_string());

    let mut cache_file = File::create(&file_path)
        .await
        .context("failed to create cache file")?;
    let mut stream = resp.bytes_stream();

    while let Some(chunk) = stream.next().await {
        let chunk = chunk.context("failed to download file")?;
        cache_file
            .write_all(&chunk)
            .await
            .context("failed to write to cache file")?;

        current += chunk.len() as u64;
        progress.set_position(current.min(total_size));
    }

    progress.finish();

    Ok(Some(file_path))
}

pub(crate) fn bgpkit_elem_into_event(
    elem: bgpkit_parser::BgpElem,
    host: String,
) -> anyhow::Result<Event> {
    let timestamp = timestamp_into_chrono(elem.timestamp)?;
    let prefix = bgpkit_prefix_into_cidr(elem.prefix).context("failed to convert prefix")?;

    let typ = if elem.is_announcement() {
        // let mut as_path = elem.as_path.context("missing as path")?;
        // as_path.dedup_coalesce();

        let origin_asn = elem
            .origin_asns
            .context("missing origins asns")?
            .into_iter()
            .map(|asn| asn.to_u32())
            .collect();

        // let mut path = Vec::new();

        // for seg in as_path.segments {
        //     match seg {
        //         AsPathSegment::AsSequence(seq) => path.extend(
        //             seq.into_iter()
        //                 .map(|asn| serde_json::Value::from(asn.to_u32())),
        //         ),
        //         AsPathSegment::AsSet(set) => path.push(serde_json::Value::Array(
        //             set.into_iter()
        //                 .map(|asn| serde_json::Value::from(asn.to_u32()))
        //                 .collect(),
        //         )),
        //         _ => anyhow::bail!("invalid as path"),
        //     }
        // }

        EventType::Announcement(Announcement {
            prefix,
            origin_asn,
            peer_asn: elem.peer_asn.to_u32(),
            peer_ip: elem.peer_ip,
            host,
            next_hop: elem.next_hop.map(|h| vec![h]).unwrap_or_default(),
            // as_path: serde_json::Value::Array(path),
        })
    } else {
        EventType::Withdrawal(Withdrawal {
            prefix,
            peer_asn: elem.peer_asn.to_u32(),
            peer_ip: elem.peer_ip,
            host,
        })
    };

    Ok(Event { timestamp, typ })
}

pub(crate) fn bgpkit_prefix_into_cidr(
    prefix: bgpkit_parser::models::NetworkPrefix,
) -> Result<IpCidr, cidr::errors::NetworkParseError> {
    IpCidr::new(prefix.prefix.addr(), prefix.prefix.prefix_len())
}
