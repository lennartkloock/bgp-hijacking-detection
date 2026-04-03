use moas_analysis::{global::Global, service::MoasAnalysisSvc};

scuffle_bootstrap::main! {
    Global {
        scuffle_signal::SignalSvc,
        MoasAnalysisSvc,
    }
}
