#![cfg_attr(docsrs, feature(doc_auto_cfg))]
#![deny(unsafe_code)]
#![deny(unreachable_pub)]
#![deny(clippy::mod_module_files)]

mod config;
mod service;

pub use config::ProfilingConfig;
pub use service::ProfilingSvc;
