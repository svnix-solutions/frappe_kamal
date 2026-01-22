# ERPNext Kamal Deployment

Deploy ERPNext on VPS servers using [Kamal](https://kamal-deploy.org/) with MariaDB master-slave replication.

## Features

- 🚀 Zero-downtime deployments with Kamal
- 🔄 MariaDB master-slave replication (GTID-based)
- 💾 Automated daily backups with 7-day retention
- 🔒 SSL/TLS via Kamal proxy
- 📦 Docker Hub registry integration
- 🛠️ Custom app support via `apps.json`

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

### 2. Configure Apps (Optional)

Edit `apps.json` to add custom Frappe apps:

```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/your-org/custom-app",
    "branch": "main"
  }
]
```

For private repos, use: `https://{PAT}@github.com/org/repo.git`

### 3. Set Environment Variables

```bash
export DOCKERHUB_TOKEN="your-docker-hub-token"
export MYSQL_ROOT_PASSWORD="$(openssl rand -base64 32)"
export MYSQL_PASSWORD="$(openssl rand -base64 32)"
export REPLICATION_USER="repl_user"
export REPLICATION_PASSWORD="$(openssl rand -base64 32)"
export ERPNEXT_ADMIN_PASSWORD="your-admin-password"
export KAMAL_MASTER_HOST="your-master-ip"
export KAMAL_SLAVE_HOST="your-slave-ip"

# Generate base64 encoded apps.json for build
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)
```

### 4. Deploy

```bash
# Setup servers (first time only)
kamal setup

# Or deploy updates
kamal deploy
```

## Custom Image Build

The Dockerfile uses the [frappe_docker](https://github.com/frappe/frappe_docker) pattern with multi-stage builds:

1. **Base stage**: System dependencies, Node.js, Python
2. **Builder stage**: Installs Frappe and apps from `apps.json`
3. **Production stage**: Minimal runtime image

Build args:
- `FRAPPE_VERSION`: Frappe branch (default: `version-15`)
- `PYTHON_VERSION`: Python version (default: `3.11.9`)
- `NODE_VERSION`: Node.js version (default: `18.20.2`)
- `APPS_JSON_BASE64`: Base64-encoded apps.json

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
├── apps.json               # Frappe apps to install
├── Dockerfile              # Multi-stage ERPNext build
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
