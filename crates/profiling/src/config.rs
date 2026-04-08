use std::net::SocketAddr;

use scuffle_bootstrap::Global;

pub trait ProfilingConfig: Global {
    fn bind(&self) -> Option<SocketAddr>;
}
