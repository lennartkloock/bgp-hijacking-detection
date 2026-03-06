FROM rust:latest AS build
WORKDIR /build
COPY . .
RUN cargo build --release

FROM debian:stable-slim
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=build /build/target/release/ingest /app/ingest
WORKDIR /app
ENTRYPOINT [ "/app/ingest" ]
