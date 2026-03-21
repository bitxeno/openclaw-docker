FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies and tools
# software-properties-common will lead to lsetxattr security.capability error
RUN apt-get update && apt-get install -y \
    s6-overlay \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    unzip \
    zip \
    jq \
    rclone

# Install Python 3
RUN apt-get install -y \
    python3 \
    python3-venv \
    python3-dev \
    && apt-get install -y python3-pip

# Set Python 3 as default and create alias
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Create openclaw user and workspace
RUN useradd -m -s /bin/bash openclaw && \
    mkdir -p /home/openclaw/workspace && \
    chown -R openclaw:openclaw /home/openclaw && \
    apt-get install -y sudo && \
    echo "openclaw ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/openclaw && \
    chmod 0440 /etc/sudoers.d/openclaw

# Copy opencode config to workspace
RUN mkdir -p /home/openclaw/.config/opencode && \
    chown -R openclaw:openclaw /home/openclaw/.config/opencode
COPY opencode.json /home/openclaw/.config/opencode/
RUN chown openclaw:openclaw /home/openclaw/.config/opencode/opencode.json

# Set working directory
WORKDIR /home/openclaw/workspace

# Install Node.js (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="${PATH}:/root/.bun/bin"

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="${PATH}:/root/.cargo/bin"

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
ENV PATH="${PATH}:/usr/local/go/bin"

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="${PATH}:/root/.cargo/bin"

# Install OpenCode CLI
RUN curl -fsSL https://opencode.ai/install | bash && \
    export PATH="${PATH}:$(find /root -name opencode -type f -executable 2>/dev/null | xargs dirname | head -1)" || true
ENV PATH="${PATH}:/root/.local/bin:/root/.opencode/bin"

# Install jj
RUN ARCH=$(uname -m); \
    mkdir -p /usr/local/jj && \
    wget https://github.com/jj-vcs/jj/releases/download/v0.39.0/jj-v0.39.0-${ARCH}-unknown-linux-musl.tar.gz && \
    tar -C /usr/local/jj -xzf jj-v0.39.0-${ARCH}-unknown-linux-musl.tar.gz && \
    rm jj-v0.39.0-${ARCH}-unknown-linux-musl.tar.gz
ENV PATH="${PATH}:/usr/local/jj"

# Install OpenClaw
RUN npm install -g openclaw@latest

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

# Set proper permissions for workspace
RUN chown -R openclaw:openclaw /home/openclaw/workspace

# Switch to openclaw user
USER openclaw

# Copy s6-overlay services scripts
COPY services.d /etc/services.d
RUN chown -R openclaw:openclaw /etc/services.d && \
    chmod +x /etc/services.d/*/run

# Set s6-overlay entrypoint
ENTRYPOINT ["/init"]
