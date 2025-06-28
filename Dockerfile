# Use Ubuntu as base image with ttyd pre-compiled
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/bin/bash
ENV TERM=xterm-256color

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    net-tools \
    iputils-ping \
    telnet \
    sudo \
    build-essential \
    cmake \
    libwebsockets-dev \
    libjson-c-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Build ttyd from source
RUN git clone https://github.com/tsl0922/ttyd.git /tmp/ttyd \
    && cd /tmp/ttyd && mkdir build && cd build \
    && cmake .. \
    && make && make install \
    && cd / && rm -rf /tmp/ttyd

# Working directory
WORKDIR /workspace

# Health check script
RUN echo '#!/bin/bash' > /health.sh && \
    echo 'curl -f http://localhost:${PORT:-8080}/ > /dev/null 2>&1 || exit 1' >> /health.sh && \
    chmod +x /health.sh

# Startup script
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo 'echo "=== Web Terminal Starting ==="' >> /start.sh && \
    echo 'TERMINAL_PASSWORD=${TERMINAL_PASSWORD:-defaultpassword}' >> /start.sh && \
    echo 'PORT=${PORT:-8080}' >> /start.sh && \
    echo 'echo \"Port: \$PORT\"' >> /start.sh && \
    echo 'echo \"Username: admin\"' >> /start.sh && \
    echo 'echo \"Password: [CONFIGURED]\"' >> /start.sh && \
    echo 'exec ttyd --port \"\$PORT\" --interface \"0.0.0.0\" --credential \"admin:\$TERMINAL_PASSWORD\" --writable --max-clients 5 bash -l' >> /start.sh && \
    chmod +x /start.sh

# Test
RUN ttyd --version

# Expose port
EXPOSE 8080

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /health.sh

# Run as root
USER root

# Start terminal on launch
CMD ["/start.sh"]
