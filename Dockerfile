ARG BIN

FROM rust:latest AS build
ARG BIN
WORKDIR /build
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
