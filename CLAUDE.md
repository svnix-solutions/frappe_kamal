# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kamal deployment configuration for ERPNext on a single VPS server.

## Architecture

```
┌─────────────────────────────────────────┐
│              VPS Server                 │
├─────────────────────────────────────────┤
│  ├── web (supervisor)                   │
│  │   ├── nginx (port 8080)              │
│  │   ├── gunicorn (port 8000)           │
│  │   └── socketio (port 9000)           │
│  ├── worker (background jobs)           │
│  ├── db (MariaDB)                       │
│  ├── redis-cache                        │
│  ├── redis-queue                        │
│  └── db-backup                          │
└─────────────────────────────────────────┘
```

- **Web Container**: Runs nginx, gunicorn, and socketio via supervisor
- **Backups**: Daily at 2 AM, 7-day retention via `fradelg/mysql-cron-backup`
- **Image Registry**: Docker Hub

## Common Commands

```bash
# Deploy application
kamal deploy

# Boot all accessories (database, redis, backup)
kamal accessory boot all

# Boot specific accessory
kamal accessory boot db

# Check deployment status
kamal app details

# Access application shell
kamal shell

# Access ERPNext bench console
kamal console

# View logs
kamal logs

# Manual database backup
kamal db-backup-now

# Access database shell
kamal db-shell

# Configure site (run once after first deploy)
kamal app exec "configure.sh"
```

## Required Environment Variables

Set these before deploying:

```bash
export DOCKERHUB_TOKEN="docker-hub-access-token"
export MYSQL_ROOT_PASSWORD="strong-password"
export ERPNEXT_ADMIN_PASSWORD="admin-password"
export PRIMARY_HOST="server-ip"
export ERPNEXT_DOMAIN="erp.example.com"
```

## Key Files

- `config/deploy.yml` - Main Kamal configuration (servers, accessories, env vars)
- `.kamal/secrets` - Secret mappings (reads from environment variables)
- `.kamal/hooks/pre-deploy` - Directory setup and database health checks
- `config/mariadb/mariadb.cnf` - MariaDB configuration
- `config/supervisor/` - Supervisor configuration for web container
- `config/frappe/configure.sh` - Site initialization script

## Before First Deploy

1. Update `config/deploy.yml`:
   - Replace `your-dockerhub-username` with actual username
   - Replace `192.168.0.1` with actual server IP
   - Replace `erp.example.com` with actual domain

2. Set all required environment variables

3. Ensure SSH access to server: `ssh root@your-server-ip`

4. After first deploy, run: `kamal app exec "configure.sh"`
