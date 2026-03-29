use detection::global::Global;
use detection::service::DetectionSvc;

#[cfg(not(target_env = "msvc"))]
use tikv_jemallocator::Jemalloc;

#[cfg(not(target_env = "msvc"))]
#[global_allocator]
static GLOBAL: Jemalloc = Jemalloc;

scuffle_bootstrap::main! {
    Global {
        scuffle_signal::SignalSvc,
        DetectionSvc,
    }
}
