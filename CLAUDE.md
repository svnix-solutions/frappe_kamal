# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kamal deployment configuration for ERPNext on VPS servers with MariaDB master-slave replication.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      VPS Servers                            │
├─────────────────────────────┬───────────────────────────────┤
│  Server 1 (Master)          │  Server 2 (Slave)             │
│  ├── erpnext (web)          │  ├── erpnext (worker)         │
│  ├── db-master (MariaDB)    │  └── db-slave (MariaDB)       │
│  ├── redis-cache            │                               │
│  ├── redis-queue            │                               │
│  └── db-backup              │                               │
└─────────────────────────────┴───────────────────────────────┘
```

- **MariaDB Replication**: GTID-based master-slave, configured automatically via `post-accessory-boot` hook
- **Backups**: Daily at 2 AM, 7-day retention via `fradelg/mysql-cron-backup`
- **Image Registry**: Docker Hub

## Common Commands

```bash
# Deploy application
kamal deploy

# Boot all accessories (databases, redis, backup)
kamal accessory boot all

# Boot specific accessory
kamal accessory boot db-master

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
```

## Required Environment Variables

Set these before deploying:

```bash
export DOCKERHUB_TOKEN="docker-hub-access-token"
export MYSQL_ROOT_PASSWORD="strong-password"
export MYSQL_PASSWORD="strong-password"
export REPLICATION_USER="repl_user"
export REPLICATION_PASSWORD="strong-password"
export ERPNEXT_ADMIN_PASSWORD="admin-password"
export KAMAL_MASTER_HOST="master-server-ip"
export KAMAL_SLAVE_HOST="slave-server-ip"
```

## Key Files

- `config/deploy.yml` - Main Kamal configuration (servers, accessories, env vars)
- `.kamal/secrets` - Secret mappings (reads from environment variables)
- `.kamal/hooks/post-accessory-boot` - Automatic replication setup
- `.kamal/hooks/pre-deploy` - Database health checks before deploy
- `config/mariadb/master.cnf` - MariaDB master configuration
- `config/mariadb/slave.cnf` - MariaDB slave configuration (read-only)

## Before First Deploy

1. Update `config/deploy.yml`:
   - Replace `your-dockerhub-username` with actual username
   - Replace `192.168.0.1` / `192.168.0.2` with actual server IPs
   - Replace `erp.example.com` with actual domain

2. Set all required environment variables

3. Ensure SSH access to servers: `ssh root@your-server-ip`
