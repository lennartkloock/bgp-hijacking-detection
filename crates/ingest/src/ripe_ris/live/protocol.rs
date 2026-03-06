#![allow(unused)] // this aims to be a full protocol implementation, even though not all features are used

use std::{net::IpAddr, str::FromStr};

use serde::Deserialize;

/// https://ris-live.ripe.net/manual/#client-messages
#[derive(Debug, Clone, serde::Serialize, PartialEq)]
#[serde(tag = "type", content = "data", rename_all = "snake_case")]
pub(crate) enum RisLiveClientMessage {
    RisSubscribe(RisLiveSubscriptionFilter),
    RisUnsubscribe(RisLiveSubscriptionFilter),
    RequestRrcList,
    Ping,
}

#[derive(Debug, Default, Clone, serde::Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub(crate) struct RisLiveSubscriptionFilter {
    host: Option<String>,
    #[serde(rename = "type")]
    typ: Option<String>,
    require: Option<String>,
    peer: Option<String>,
    prefix: Option<Vec<cidr::IpCidr>>,
    more_specific: Option<bool>,
    less_specific: Option<bool>,
    socket_options: Option<RisLiveSocketOptions>,
}

#[derive(Debug, Clone, serde::Deserialize, serde::Serialize, PartialEq)]
#[serde(rename_all = "camelCase")]
pub(crate) struct RisLiveSocketOptions {
    pub include_raw: Option<bool>,
    pub acknowledge: Option<bool>,
}

fn u32_from_str<'de, D>(deserializer: D) -> Result<u32, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let s = String::deserialize(deserializer)?;
    u32::from_str(&s).map_err(serde::de::Error::custom)
}

/// https://ris-live.ripe.net/manual/#server-messages
#[derive(Debug, Clone, serde::Deserialize, PartialEq)]
#[serde(tag = "type", content = "data", rename_all = "snake_case")]
#[allow(clippy::large_enum_variant)] // most of the time it's a RisMessage anyway
pub(crate) enum RisLiveServerMessage {
    RisMessage {
        timestamp: f64,
        peer: IpAddr,
        #[serde(deserialize_with = "u32_from_str")]
        peer_asn: u32,
        id: String,
        raw: Option<String>,
        host: String,
        #[serde(flatten)]
        typ: RisMessageType,
    },
    RisError {
        message: String,
    },
    RisRrcList,
    RisSubscribeOk {
        subscription: serde_json::Value,
        #[serde(rename = "socketOptions")]
        socket_options: RisLiveSocketOptions,
    },
    Pong,
}

#[derive(Debug, Clone, serde::Deserialize, PartialEq, Eq)]
#[serde(tag = "type", rename_all = "SCREAMING_SNAKE_CASE")]
pub(crate) enum RisMessageType {
    Update {
        path: Option<Vec<AsPathElement>>,
        community: Option<Vec<BgpCommunity>>,
        origin: Option<String>,
        med: Option<i32>,
        aggregator: Option<String>,
        announcements: Option<Vec<RisMessageUpdateAnnouncement>>,
        withdrawals: Option<Vec<cidr::IpCidr>>,
    },
    Keepalive,
    Open {
        direction: RisMessageOpenDirection,
        version: u8,
        asn: u32,
        hold_time: u32,
        router_id: String,
        capabilities: serde_json::Value,
    },
    Notification {
        notification: RisMessageNotification,
    },
    State {
        state: RisPeerState,
    },
}

#[derive(Debug, Clone, serde::Deserialize, PartialEq, Eq)]
#[serde(untagged)]
pub(crate) enum AsPathElement {
    Asn(u32),
    AsSet(Vec<u32>),
}

impl From<u32> for AsPathElement {
    fn from(value: u32) -> Self {
        Self::Asn(value)
    }
}

impl AsPathElement {
    pub(crate) fn to_vec(&self) -> Vec<u32> {
        match self {
            AsPathElement::Asn(asn) => vec![*asn],
            AsPathElement::AsSet(set) => set.clone(),
        }
    }
}

// impl AsPathElement {
//     /// Splits the given path into multiple paths if it ends in an AS set.
//     /// If it doesn't end in an AS set, returns just one path.
//     ///
//     /// Returns an error if there is an AS set which doesn't appear at the end of the path.
//     pub(crate) fn split_path(path: &[AsPathElement]) -> anyhow::Result<Vec<Vec<u32>>> {
//         let mut paths = Vec::new();

//         match path.split_last() {
//             None => {}
//             Some((AsPathElement::AsSet(as_set), path_except_last)) => {
//                 let path: Vec<_> = path_except_last
//                     .into_iter()
//                     .map(|asn| match asn {
//                         AsPathElement::AsSet(_) => anyhow::bail!("as set cannot be in path"),
//                         AsPathElement::Asn(asn) => Ok(*asn),
//                     })
//                     .collect::<Result<_, _>>()?;

//                 for asn in as_set {
//                     let mut path = path.clone();
//                     path.push(*asn);
//                     paths.push(path);
//                 }
//             }
//             Some((AsPathElement::Asn(_), _)) => {
//                 let path = path
//                     .into_iter()
//                     .map(|asn| match asn {
//                         AsPathElement::AsSet(_) => anyhow::bail!("as set cannot be in path"),
//                         AsPathElement::Asn(asn) => Ok(*asn),
//                     })
//                     .collect::<Result<_, _>>()?;
//                 paths.push(path);
//             }
//         }

//         Ok(paths)
//     }
// }

#[derive(Debug, Clone, serde::Deserialize, PartialEq, Eq)]
pub(crate) struct BgpCommunity(pub u32, pub u32);

fn deserialize_comma_seperated<'de, D, T: FromStr>(deserializer: D) -> Result<Vec<T>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let s = String::deserialize(deserializer)?;

    let vec = s
        .split(',')
        .map(|s| T::from_str(s))
        .collect::<Result<_, _>>()
        .map_err(|_| serde::de::Error::custom("failed to parse type from string"))?;

    Ok(vec)
}

#[derive(Debug, Clone, serde::Deserialize, PartialEq, Eq)]
pub(crate) struct RisMessageUpdateAnnouncement {
    #[serde(deserialize_with = "deserialize_comma_seperated")]
    pub next_hop: Vec<IpAddr>,
    pub prefixes: Vec<cidr::IpCidr>,
}

#[derive(Debug, Clone, serde::Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub(crate) enum RisMessageOpenDirection {
    Sent,
    Received,
}

#[derive(Debug, Clone, serde::Deserialize, PartialEq, Eq)]
pub(crate) struct RisMessageNotification {
    pub code: i32,
    pub subcode: Option<i32>,
    pub data: Option<String>,
}

#[derive(Debug, Clone, serde::Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub(crate) enum RisPeerState {
    Connected,
    Up,
    Down,
}

#[cfg(test)]
mod tests {
    use crate::ripe_ris::live::protocol::{
        AsPathElement, BgpCommunity, RisLiveServerMessage, RisMessageType,
        RisMessageUpdateAnnouncement,
    };

    // #[test]
    // fn split_paths() {
    //     let path1 = [AsPathElement::Asn(1), AsPathElement::Asn(2), AsPathElement::Asn(3), AsPathElement::Asn(4)];
    //     assert_eq!(AsPathElement::split_path(&path1).unwrap(), vec![vec![1, 2, 3, 4]]);

    //     let path2 = [AsPathElement::Asn(1), AsPathElement::Asn(2), AsPathElement::Asn(3), AsPathElement::AsSet(vec![4, 5])];
    //     assert_eq!(AsPathElement::split_path(&path2).unwrap(), vec![vec![1, 2, 3, 4], vec![1, 2, 3, 5]]);
    // }

    #[test]
    fn ris_message_example_deserialize() {
        let message = r#"
            {
                "type": "ris_message",
                "data": {"timestamp":1568279357.18,"peer":"192.0.2.0","peer_asn":"64496","id":"21-192-0-2-0-11187052","host":"rrc21","type":"KEEPALIVE"}
            }
        "#;

        let deserialized: RisLiveServerMessage = serde_json::from_str(message).unwrap();

        assert_eq!(
            deserialized,
            RisLiveServerMessage::RisMessage {
                timestamp: 1568279357.18,
                peer: "192.0.2.0".parse().unwrap(),
                peer_asn: 64496,
                id: "21-192-0-2-0-11187052".to_string(),
                raw: None,
                host: "rrc21".to_string(),
                typ: RisMessageType::Keepalive,
            }
        );
    }

    #[test]
    fn pong_example_deserialize() {
        let message = r#"
            {
                "type": "pong",
                "data": null
            }
        "#;

        let deserialized: RisLiveServerMessage = serde_json::from_str(message).unwrap();

        assert_eq!(deserialized, RisLiveServerMessage::Pong);
    }

    #[test]
    fn real_message() {
        let message = r#"
        {
            "type": "ris_message",
            "data": {
                "timestamp": 1771179888.49,
                "peer": "2001:7f8:d:ff::96",
                "peer_asn": "35280",
                "id": "2001:7f8:d:ff::96-019c628c4f6a0001",
                "host": "rrc07.ripe.net",
                "type": "UPDATE",
                "path": [35280, 2914, 3356, 7720, 208754],
                "community": [[2914, 420], [2914, 1206], [2914, 2203], [2914, 3200], [3356, 4], [3356, 22]],
                "origin": "IGP",
                "announcements": [
                    {
                        "next_hop": "2001:7f8:d:ff::96,fe80::8a90:900:d7f8:eac5",
                        "prefixes": [
                            "2a14:67c1:a112::/48"
                        ]
                    }
                ],
                "withdrawals": []
            }
        }
        "#;

        let deserialized: RisLiveServerMessage = serde_json::from_str(message).unwrap();

        assert_eq!(
            deserialized,
            RisLiveServerMessage::RisMessage {
                timestamp: 1771179888.49,
                peer: "2001:7f8:d:ff::96".parse().unwrap(),
                peer_asn: 35280,
                id: "2001:7f8:d:ff::96-019c628c4f6a0001".to_string(),
                raw: None,
                host: "rrc07.ripe.net".to_string(),
                typ: RisMessageType::Update {
                    path: Some(vec![
                        35280.into(),
                        2914.into(),
                        3356.into(),
                        7720.into(),
                        208754.into()
                    ]),
                    community: Some(vec![
                        BgpCommunity(2914, 420),
                        BgpCommunity(2914, 1206),
                        BgpCommunity(2914, 2203),
                        BgpCommunity(2914, 3200),
                        BgpCommunity(3356, 4),
                        BgpCommunity(3356, 22)
                    ]),
                    origin: Some("IGP".to_string()),
                    med: None,
                    aggregator: None,
                    announcements: Some(vec![RisMessageUpdateAnnouncement {
                        next_hop: vec![
                            "2001:7f8:d:ff::96".parse().unwrap(),
                            "fe80::8a90:900:d7f8:eac5".parse().unwrap()
                        ],
                        prefixes: vec!["2a14:67c1:a112::/48".parse().unwrap()],
                    }]),
                    withdrawals: Some(vec![]),
                },
            },
        );
    }
}
