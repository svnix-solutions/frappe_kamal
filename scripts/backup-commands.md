# Database Backup & Restore Commands

## Automatic Backups
Backups run automatically daily at 2 AM via the `db-backup` accessory.
- Location: `/backup` directory inside the container
- Retention: 7 days (configurable via `MAX_BACKUPS`)
- Format: Gzipped SQL dumps

## Manual Backup Commands

### Trigger immediate backup
```bash
kamal accessory exec db-backup "/backup.sh"
```

### List existing backups
```bash
kamal accessory exec db-backup "ls -la /backup"
```

### Download a backup to local machine
```bash
# First, find the backup file name
kamal accessory exec db-backup "ls /backup"

# Copy backup from server (run on your local machine)
scp root@YOUR_SERVER_IP:/var/lib/docker/volumes/erpnext-db-backup-backups/_data/BACKUP_FILE.sql.gz ./
```

## Manual Database Dump (without backup service)

### Full database dump
```bash
kamal accessory exec db-master "mariadb-dump -u root -p --all-databases --single-transaction --routines --triggers" > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Single database dump
```bash
kamal accessory exec db-master "mariadb-dump -u root -p erpnext --single-transaction --routines --triggers" > erpnext_$(date +%Y%m%d_%H%M%S).sql
```

## Restore Commands

### Restore from backup file
```bash
# Copy backup to server first
scp backup.sql.gz root@YOUR_SERVER_IP:/tmp/

# Decompress if gzipped
kamal accessory exec db-master "gunzip /tmp/backup.sql.gz"

# Restore
kamal accessory exec db-master "mariadb -u root -p erpnext < /tmp/backup.sql"
```

### Restore to slave (for rebuilding replication)
```bash
# 1. Stop slave
kamal accessory exec db-slave "mariadb -u root -p -e 'STOP SLAVE'"

# 2. Restore the backup
kamal accessory exec db-slave "mariadb -u root -p < /tmp/backup.sql"

# 3. Restart replication (run setup-replication.sh)
./scripts/setup-replication.sh
```

## ERPNext-Specific Backup

ERPNext also has its own backup command which backs up database + files:

```bash
# Using bench backup
kamal app exec "bench --site erp.example.com backup --with-files"

# Backups are stored in: sites/erp.example.com/private/backups/
kamal app exec "ls -la /home/frappe/frappe-bench/sites/erp.example.com/private/backups/"
```

## Offsite Backup (Optional S3 Configuration)

To enable S3 backups, update the `db-backup` accessory in deploy.yml:

```yaml
db-backup:
  image: fradelg/mysql-cron-backup:latest
  env:
    clear:
      # ... existing config ...
      # S3 Configuration
      AWS_ACCESS_KEY_ID: your-access-key
      AWS_DEFAULT_REGION: us-east-1
      S3_BUCKET: your-backup-bucket
    secret:
      - MYSQL_PASS
      - AWS_SECRET_ACCESS_KEY
```

## Monitoring Replication

### Check replication status
```bash
kamal accessory exec db-slave "mariadb -u root -p -e 'SHOW SLAVE STATUS\G'" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master"
```

### Expected output (healthy):
```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
```
