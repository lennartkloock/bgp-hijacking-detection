#![cfg_attr(docsrs, feature(doc_auto_cfg))]
#![deny(unsafe_code)]
#![deny(unreachable_pub)]
#![deny(clippy::mod_module_files)]

pub mod bgp;
pub mod config;
pub mod global;
pub(crate) mod ripe_ris;
pub mod service;
