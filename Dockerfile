FROM debian:buster-slim

# Set non-interactive environment variable
ARG DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests curl ca-certificates pkg-config libssl-dev libpq-dev openssl libpq5 && \
    sed -i -e 's,\[ v3_req \],\[ v3_req \]\nextendedKeyUsage = serverAuth,' /etc/ssl/openssl.cnf

# Download and install the latest Rust version
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# Set cargo environment variables
ENV CARGO_HOME=/root/.cargo
ENV CARGO_TARGET_DIR=/root/target

# Install diesel_cli and other dependencies
RUN cargo install diesel_cli --no-default-features --features postgres

# Copy your application code
COPY common /lumen/common
COPY lumen /lumen/lumen
COPY Cargo.toml /lumen/

# Build your application
RUN --mount=type=cache,target=$CARGO_HOME/registry,target=/lumen/target \
    cd /lumen && cargo build --release && cp /lumen/target/release/lumen /usr/bin/lumen

# Set the working directory and configure your application
WORKDIR /lumen
COPY config-example.toml docker-init.sh /lumen/
RUN chmod a+x /lumen/docker-init.sh && chmod a+x /usr/bin/lumen

# Define the startup command
STOPSIGNAL SIGINT
CMD /lumen/docker-init.sh
