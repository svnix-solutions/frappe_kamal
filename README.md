# ERPNext Kamal Deployment

Deploy ERPNext on VPS servers using [Kamal](https://kamal-deploy.org/) with MariaDB master-slave replication.

## Features

- 🚀 Zero-downtime deployments with Kamal
- 🔄 MariaDB master-slave replication (GTID-based)
- 💾 Automated daily backups with 7-day retention
- 🔒 SSL/TLS via Kamal proxy
- 📦 Docker Hub registry integration

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

## Prerequisites

- [Kamal](https://kamal-deploy.org/) installed (`gem install kamal`)
- Docker Hub account
- 2 VPS servers with SSH access (Ubuntu 22.04+ recommended)
- Domain name pointing to your web server

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/svnix-solutions/frappe_kamal.git
cd frappe_kamal
```

Edit `config/deploy.yml` and replace:
- `your-dockerhub-username` → your Docker Hub username
- `192.168.0.1` / `192.168.0.2` → your server IPs
- `erp.example.com` → your domain

### 2. Set Environment Variables

```bash
export DOCKERHUB_TOKEN="your-docker-hub-token"
export MYSQL_ROOT_PASSWORD="$(openssl rand -base64 32)"
export MYSQL_PASSWORD="$(openssl rand -base64 32)"
export REPLICATION_USER="repl_user"
export REPLICATION_PASSWORD="$(openssl rand -base64 32)"
export ERPNEXT_ADMIN_PASSWORD="your-admin-password"
export KAMAL_MASTER_HOST="your-master-ip"
export KAMAL_SLAVE_HOST="your-slave-ip"
```

### 3. Deploy

```bash
# Setup servers (first time only)
kamal setup

# Or deploy updates
kamal deploy
```

## Common Commands

| Command | Description |
|---------|-------------|
| `kamal deploy` | Deploy application |
| `kamal accessory boot all` | Start all accessories |
| `kamal shell` | Access application shell |
| `kamal console` | Access ERPNext bench console |
| `kamal logs` | View application logs |
| `kamal db-shell` | Access MariaDB shell |
| `kamal db-backup-now` | Trigger manual backup |

## Project Structure

```
.
├── config/
│   ├── deploy.yml          # Main Kamal configuration
│   └── mariadb/
│       ├── master.cnf      # MariaDB master config
│       └── slave.cnf       # MariaDB slave config
├── .kamal/
│   ├── secrets             # Secret mappings
│   └── hooks/
│       ├── post-accessory-boot  # Replication setup
│       └── pre-deploy           # Health checks
├── scripts/
│   └── backup-commands.md  # Backup/restore reference
├── Dockerfile              # ERPNext image
└── CLAUDE.md               # Claude Code guidance
```

## Backups

- **Automatic**: Daily at 2 AM, 7-day retention
- **Manual**: `kamal db-backup-now`
- **Location**: `/backup` in db-backup container

See [scripts/backup-commands.md](scripts/backup-commands.md) for restore procedures.

## Replication

MariaDB replication is configured automatically via the `post-accessory-boot` hook when you boot the database accessories.

Check replication status:
```bash
kamal accessory exec db-slave "mariadb -u root -p -e 'SHOW SLAVE STATUS\G'" | grep -E "Running|Behind"
```

## License

MIT
