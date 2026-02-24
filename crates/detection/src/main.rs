use detection::global::Global;
use detection::service::DetectionSvc;

scuffle_bootstrap::main! {
    Global {
        scuffle_signal::SignalSvc,
        DetectionSvc,
    }
}
