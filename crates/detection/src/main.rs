use detection::global::Global;
use detection::service::DetectionSvc;

#[cfg(not(target_env = "msvc"))]
use tikv_jemallocator::Jemalloc;

#[cfg(not(target_env = "msvc"))]
#[global_allocator]
static GLOBAL: Jemalloc = Jemalloc;

#[allow(non_upper_case_globals)]
#[unsafe(export_name = "malloc_conf")]
pub static malloc_conf: &[u8] = b"prof:true,prof_active:true,lg_prof_sample:19\0";

scuffle_bootstrap::main! {
    Global {
        scuffle_signal::SignalSvc,
        DetectionSvc,
        profiling::ProfilingSvc,
    }
}
