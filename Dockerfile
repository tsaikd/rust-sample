FROM rust:1 AS build
# Prepare alpine gcc tools
RUN apt update
RUN apt install -y musl-tools
RUN rustup target add x86_64-unknown-linux-musl
RUN rustup component add clippy rustfmt

# Precompile dependencies of package
ARG pkgname=hello-rust
WORKDIR /app
RUN mkdir src
RUN echo "fn main() {}" > src/main.rs
COPY Cargo.toml ./
COPY Cargo.lock ./
RUN cargo build --release --target=x86_64-unknown-linux-musl
RUN rm -rf target/x86_64-unknown-linux-musl/release/.fingerprint/${pkgname}-*

# Compile application
COPY src ./src
RUN cargo fmt --all -- --check
RUN cargo clippy --release --target=x86_64-unknown-linux-musl -- -D warnings
RUN cargo test --release --target=x86_64-unknown-linux-musl
RUN cargo build --release --target=x86_64-unknown-linux-musl

# Make release image
FROM alpine:3
COPY --from=build /app/target/x86_64-unknown-linux-musl/release/hello-rust /usr/local/bin
CMD hello-rust
