# ERPNext Production Dockerfile
# Based on official Frappe Docker images

ARG ERPNEXT_VERSION=v15.44.2
ARG FRAPPE_VERSION=v15.52.1

FROM frappe/erpnext:${ERPNEXT_VERSION}

# Set environment variables
ENV FRAPPE_SITE_NAME_HEADER=$$host \
    WORKER_CLASS=gthread \
    GUNICORN_WORKERS=4 \
    GUNICORN_THREADS=2

# Switch to root for installations if needed
USER root

# Install any additional system dependencies here
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     your-package \
#     && rm -rf /var/lib/apt/lists/*

# Switch back to frappe user
USER frappe

# Add custom apps here if needed
# Example:
# RUN bench get-app https://github.com/your-org/your-custom-app.git
# RUN bench --site all install-app your-custom-app

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/api/method/ping || exit 1
