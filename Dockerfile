FROM ubuntu:24.04
ARG S6_OVERLAY_VERSION=3.2.2.0

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies and tools
# software-properties-common will lead to lsetxattr security.capability error
RUN apt-get update && apt-get install -y \
    vim \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    unzip \
    zip \
    jq \
    rclone

RUN curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Install GitHub CLI
RUN brew install gh

# Install s6-overlay for process supervision
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && rm /tmp/s6-overlay-noarch.tar.xz
RUN ARCH=$(uname -m); \
    cd /tmp && \
    wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz && \
    rm /tmp/s6-overlay-${ARCH}.tar.xz

# Install Python 3
RUN apt-get install -y \
    python3 \
    python3-venv \
    python3-dev \
    && apt-get install -y python3-pip

# Set Python 3 as default and create alias
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Install Node.js (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Install Bun (Old CPU need to use baseline version)
RUN if [ "$(uname -m)" = "x86_64" ]; then \
      NAME=x64-baseline; \
    else \
      NAME=$(uname -m); \
    fi && \
    wget https://github.com/oven-sh/bun/releases/download/bun-v1.3.11/bun-linux-${NAME}.zip && \
    unzip bun-linux-${NAME}.zip && \
    mv bun-linux-${NAME}/bun /usr/local/bin/ && \
    rm -rf bun-linux-${NAME} bun-linux-${NAME}.zip
ENV PATH="${PATH}:/root/.bun/bin"

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="${PATH}:/root/.local/bin"

# Install Go (multi-arch)
RUN if [ "$(uname -m)" = "aarch64" ]; then \
      GOARCH=arm64; \
    elif [ "$(uname -m)" = "x86_64" ]; then \
      GOARCH=amd64; \
    else \
      GOARCH=$(uname -m); \
    fi && \
    wget https://go.dev/dl/go1.26.1.linux-${GOARCH}.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.26.1.linux-${GOARCH}.tar.gz && \
    rm go1.26.1.linux-${GOARCH}.tar.gz
ENV PATH="${PATH}:/usr/local/go/bin:/root/go/bin"

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="${PATH}:/root/.cargo/bin"

# Install jj
RUN ARCH=$(uname -m); \
    mkdir -p /usr/local/jj && \
    wget https://github.com/jj-vcs/jj/releases/download/v0.39.0/jj-v0.39.0-${ARCH}-unknown-linux-musl.tar.gz && \
    tar -C /usr/local/jj -xzf jj-v0.39.0-${ARCH}-unknown-linux-musl.tar.gz && \
    rm jj-v0.39.0-${ARCH}-unknown-linux-musl.tar.gz
ENV PATH="${PATH}:/usr/local/jj"

# Install OpenCode
RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH="${PATH}:/root/.opencode/bin"

# Install OpenClaw
RUN npm install -g openclaw@latest

# Clean up apt cache to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify installations
RUN echo "=== Python ===" && python3 --version && \
    echo "=== Node.js ===" && node --version && \
    echo "=== npm ===" && npm --version && \
    echo "=== Bun ===" && bun --version && \
    echo "=== uv ===" && uv --version && \
    echo "=== Go ===" && go version && \
    echo "=== Rust ===" && rustc --version && \
    echo "=== Cargo ===" && cargo --version && \
    echo "=== OpenCode ===" && opencode --version && \
    echo "=== Rclone ===" && rclone version


# Copy s6-overlay services scripts
COPY services.d /etc/services.d
RUN chmod +x /etc/services.d/*/run

# Copy default configuration files (if any)
COPY config /root/default-config

# Set working directory
WORKDIR /root

# Set s6-overlay entrypoint
ENTRYPOINT ["/init"]
