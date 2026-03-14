ARG BIN

FROM rust:latest AS build
ARG BIN
WORKDIR /build
COPY . .
RUN cargo build -p ${BIN} --release

FROM debian:stable-slim
ARG BIN
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=build /build/target/release/${BIN} /app/${BIN}
WORKDIR /app
ENTRYPOINT [ "/app/${BIN}" ]
