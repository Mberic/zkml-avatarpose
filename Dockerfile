# syntax=docker.io/docker/dockerfile:1

# Stage 1: Build and Install Rust + ezkl
FROM ubuntu:22.04 AS builder

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.82.0

ARG DEBIAN_FRONTEND=noninteractive
RUN <<EOF
set -e
apt update
apt install -y --no-install-recommends \
    build-essential=12.9ubuntu3 \
    ca-certificates=20240203~22.04.1 \
    g++-riscv64-linux-gnu=4:11.2.0--1ubuntu1 \
    wget=1.21.2-2ubuntu1 \
    curl \
    clang \
    cmake \
    llvm \
    libssl-dev \
    pkg-config \
    git \
    make \
    perl
EOF

# Install Rust
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
    amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db' ;; \
    arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800' ;; \
    *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.26.0/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

RUN rustup target add riscv64gc-unknown-linux-gnu

# Install ezkl CLI instead of building from source
RUN curl https://raw.githubusercontent.com/zkonduit/ezkl/main/install_ezkl_cli.sh | bash

# Stage 2: Runtime Environment
FROM --platform=linux/riscv64 cartesi/python:3.10-slim-jammy

LABEL io.cartesi.rollups.sdk_version=0.11.1
LABEL io.cartesi.rollups.ram_size=16384Mi

ARG DEBIAN_FRONTEND=noninteractive

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/* /var/log/* /var/cache/*

# Install Cartesi Machine Emulator Tools
ARG MACHINE_EMULATOR_TOOLS_VERSION=0.16.1
ADD https://github.com/cartesi/machine-emulator-tools/releases/download/v${MACHINE_EMULATOR_TOOLS_VERSION}/machine-emulator-tools-v${MACHINE_EMULATOR_TOOLS_VERSION}.deb /
RUN dpkg -i /machine-emulator-tools-v${MACHINE_EMULATOR_TOOLS_VERSION}.deb && \
    rm /machine-emulator-tools-v${MACHINE_EMULATOR_TOOLS_VERSION}.deb

ENV PATH="/opt/cartesi/bin:${PATH}"

# Copy ezkl binary from the builder stage
COPY --from=builder /usr/local/bin/ezkl /usr/local/bin/ezkl

# Dapp setup
WORKDIR /opt/cartesi/dapp
COPY ./proof.json .
COPY ./settings.json .
COPY ./vk.key .
COPY ./requirements.txt .

RUN pip install -r requirements.txt --no-cache && \
    find /usr/local/lib -type d -name __pycache__ -exec rm -r {} +

COPY ./dapp.py .

ENV ROLLUP_HTTP_SERVER_URL="http://127.0.0.1:5004"

ENTRYPOINT ["rollup-init"]
CMD ["python3", "dapp.py"]
