ARG BIN

FROM rust:latest AS chef
RUN cargo install --locked cargo-chef
WORKDIR /build

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS build
ARG BIN
COPY --from=planner /build/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build -p ${BIN} --release

FROM debian:stable-slim
LABEL org.opencontainers.image.source=https://github.com/lennartkloock/bgp-hijacking-detection
LABEL org.opencontainers.image.authors="lennart.kloock@protonmail.com"
ARG BIN
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=build /build/target/release/${BIN} /app/entrypoint
WORKDIR /app
ENTRYPOINT [ "/app/entrypoint" ]
