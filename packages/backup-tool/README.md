# backup-tool

A simple, robust backup tool for homelabs. Dockerized with privileges, designed to run on a Docker Swarm manager node as a normal Compose stack on Ubuntu Server.

## Features

- **SSH hosts (rsync)** — incremental backups of remote directories via rsync over SSH
- **Docker volumes** — backup container volumes using docker commands
- **Interactive setup** — wizard to configure hosts, paths, drives, and alerts
- **Time & size based retention** — per host/path TTL policies
- **Important data replication** — replicate critical backups to multiple drives (no RAID)
- **Compressed replicas** — replicas are compressed after copy; main backup stays uncompressed for fast rsync
- **Telegram alerts** — error notifications with exponential back-off (no spam)
- **Offline detection** — checks every 30 seconds regardless of backup schedule
- **Timed incremental backups** — configurable interval, link-dest based incremental rsync

## Quick Start

```bash
# 1. Clone and navigate to the backup-tool directory
cd packages/backup-tool

# 2. Run the interactive setup wizard
docker compose run --rm backup setup

# 3. Start the backup service
docker compose up -d

# 4. View logs
docker compose logs -f
```

## Configuration

All configuration lives in the `config/` directory (mounted at `/etc/backup-tool` in the container).

### Main config: `config/backup.conf`

| Key | Description | Default |
|-----|-------------|---------|
| `backup_dest` | Where backups are stored | `/backup` |
| `backup_interval_min` | Backup interval in minutes | `60` |
| `important_drives` | Comma-separated mount points for replication | |
| `important_folders` | Comma-separated paths relative to backup\_dest | |
| `telegram_bot_token` | Telegram bot token | |
| `telegram_chat_id` | Telegram chat ID | |

### Host configs: `config/hosts.d/<name>.conf`

One file per backup source. See `config/host.conf.example`.

| Key | Description |
|-----|-------------|
| `type` | `ssh` (rsync) or `docker` (container volumes) |
| `address` | SSH address (user@host) |
| `paths` | Comma-separated paths or volume names |
| `retention_days` | Days to keep snapshots (0 = forever) |
| `retention_max_size` | Max total size (e.g. `10G`) |

## How It Works

### Backup Cycle

1. For each configured host, back up each path:
   - **SSH hosts**: `rsync -a --delete --link-dest=<latest>` for incremental backups
   - **Docker volumes**: temporary container mount + `docker cp`
2. Apply retention policies (delete old/oversized snapshots)
3. Replicate important folders to all important drives
4. Compress replicas (main copy stays uncompressed)

### Monitoring (runs independently)

- **Offline detection**: pings all SSH hosts every 30 seconds
- **Disk space**: checks all important drives and backup destination every 60 seconds
- Alerts go to Telegram with exponential back-off (2min → 4min → 8min → ... → 8h max)
- Recovery messages are sent when issues clear

### Directory Structure

Backups are stored as timestamped snapshots:

```
/backup/
  myhost/
    var_data/
      20250101-120000/     ← full snapshot
      20250102-120000/     ← incremental (hardlinked to previous)
      latest -> 20250102-120000
    home_user/
      ...
```

Replicas on important drives:

```
/mnt/usb1/
  backup-replicas/
    myhost_var_data.tar.gz   ← compressed copy
    myhost_home_user.tar.gz
```

## Commands

```bash
# Run continuous backup + monitoring (default)
docker compose run --rm backup run

# Run a single backup cycle
docker compose run --rm backup once

# Interactive setup wizard
docker compose run --rm backup setup

# Run only the monitor (offline/disk checks)
docker compose run --rm backup monitor

# Run only retention cleanup
docker compose run --rm backup retention

# Run only replication
docker compose run --rm backup replicate
```

## Telegram Bot Setup

1. Open Telegram and search for **@BotFather**
2. Send `/newbot` and follow the prompts
3. BotFather gives you a **bot token** — e.g. `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`
4. Open a chat with your new bot and send `/start`
5. Get your **chat ID** by visiting:
   ```
   https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
   ```
   Look for `"chat":{"id":NNNNNN}` in the response
6. Add both values to your config:
   ```
   telegram_bot_token=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
   telegram_chat_id=123456789
   ```

### Alert Behavior

| Alert | Check interval | Back-off |
|-------|---------------|----------|
| Host offline | 30 seconds | 2min → 4min → 8min → ... → 8h |
| Disk space > 90% | 60 seconds | 2min → 4min → 8min → ... → 8h |
| Backup/rsync error | Per backup cycle | 2min → 4min → 8min → ... → 8h |

Recovery messages are sent when the condition clears, and the back-off timer resets.

## Requirements

- Docker Engine with docker compose plugin
- Ubuntu Server (host)
- SSH key-based authentication to backup targets (for SSH hosts)
- Docker socket access (for container volume backups)

## Docker Compose Reference

```yaml
services:
  backup:
    build: .
    privileged: true
    network_mode: host
    volumes:
      - ./config:/etc/backup-tool          # Configuration
      - backup-state:/var/lib/backup-tool  # Alert state
      - backup-logs:/var/log/backup-tool   # Logs
      - /backup:/backup                    # Backup destination
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ~/.ssh:/root/.ssh:ro               # SSH keys for rsync
```

The container needs:
- **privileged** — access to host devices and Docker socket
- **network_mode: host** — SSH to remote hosts without port mapping
- **Docker socket** — to query Swarm nodes and copy from volumes
- **SSH keys** — for passwordless rsync to remote hosts
