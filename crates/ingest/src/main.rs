use ingest::global::Global;
use ingest::service::IngestSvc;

scuffle_bootstrap::main! {
    Global {
        scuffle_signal::SignalSvc,
        IngestSvc,
    }
}
