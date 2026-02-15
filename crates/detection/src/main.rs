use detection::global::Global;
use detection::services::DetectionSvc;

scuffle_bootstrap::main! {
    Global {
        scuffle_signal::SignalSvc,
        DetectionSvc,
    }
}
