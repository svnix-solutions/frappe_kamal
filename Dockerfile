# ERPNext Custom Image Build
# Based on frappe_docker build pattern
# https://github.com/frappe/frappe_docker

# Build args
ARG FRAPPE_VERSION=version-15
ARG ERPNEXT_VERSION=version-15
ARG PYTHON_VERSION=3.11.9
ARG NODE_VERSION=18.20.2

# =============================================================================
# Stage 1: Base image with system dependencies
# =============================================================================
FROM python:${PYTHON_VERSION}-slim-bookworm AS base

ARG NODE_VERSION

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    curl \
    git \
    nano \
    # Database clients
    mariadb-client \
    # Build dependencies for wkhtmltopdf
    fontconfig \
    libfreetype6 \
    libjpeg62-turbo \
    libpng16-16 \
    libx11-6 \
    libxcb1 \
    libxext6 \
    libxrender1 \
    xfonts-75dpi \
    xfonts-base \
    # Nginx
    nginx \
    # Supervisor
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install wkhtmltopdf
RUN curl -sLO https://github.com/AgarwalConsulting/frappe-install/releases/download/wkhtmltox-0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && dpkg -i wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && rm wkhtmltox_0.12.6.1-3.bookworm_amd64.deb

# Install Node.js via nvm
ENV NVM_DIR=/home/frappe/.nvm
ENV PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}"

RUN useradd -ms /bin/bash frappe \
    && mkdir -p ${NVM_DIR} \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . ${NVM_DIR}/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm use ${NODE_VERSION} \
    && npm install -g yarn \
    && chown -R frappe:frappe ${NVM_DIR}

# Install frappe-bench
RUN pip install --no-cache-dir frappe-bench

# Configure nginx for non-root
RUN touch /run/nginx.pid \
    && chown -R frappe:frappe /var/lib/nginx /var/log/nginx /run/nginx.pid

# =============================================================================
# Stage 2: Builder - install frappe and apps
# =============================================================================
FROM base AS builder

ARG FRAPPE_VERSION
ARG APPS_JSON_BASE64

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    libffi-dev \
    libbz2-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe

# Decode apps.json if provided
RUN if [ -n "${APPS_JSON_BASE64}" ]; then \
        echo "${APPS_JSON_BASE64}" | base64 -d > /home/frappe/apps.json; \
    fi

# Initialize frappe-bench with apps
RUN . ${NVM_DIR}/nvm.sh \
    && if [ -f /home/frappe/apps.json ]; then \
        bench init --frappe-branch=${FRAPPE_VERSION} --apps_path=/home/frappe/apps.json --skip-redis-config-generation frappe-bench; \
    else \
        bench init --frappe-branch=${FRAPPE_VERSION} --skip-redis-config-generation frappe-bench; \
    fi

WORKDIR /home/frappe/frappe-bench

# Build assets
RUN . ${NVM_DIR}/nvm.sh \
    && bench build --production

# Cleanup to reduce image size
RUN rm -rf \
    /home/frappe/apps.json \
    /home/frappe/frappe-bench/apps/*/.git \
    /home/frappe/frappe-bench/apps/*/node_modules \
    /home/frappe/.cache

# =============================================================================
# Stage 3: Production image
# =============================================================================
FROM base AS production

USER frappe
WORKDIR /home/frappe/frappe-bench

# Copy frappe-bench from builder
COPY --from=builder --chown=frappe:frappe /home/frappe/frappe-bench /home/frappe/frappe-bench

# Environment variables
ENV FRAPPE_SITE_NAME_HEADER=$$host \
    WORKER_CLASS=gthread \
    GUNICORN_WORKERS=4 \
    GUNICORN_THREADS=2

# Volumes for persistent data
VOLUME ["/home/frappe/frappe-bench/sites", "/home/frappe/frappe-bench/logs"]

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:8000/api/method/ping || exit 1

# Default command - run gunicorn
CMD ["bench", "serve", "--port", "8000"]
