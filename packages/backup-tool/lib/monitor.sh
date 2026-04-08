#!/usr/bin/env bash
# shellcheck shell=bash
# Background monitor — runs independently of backup schedule.
#  • Host-online checks every 30 s
#  • Disk-space checks every 60 s

MONITOR_PING_INTERVAL=30
MONITOR_DISK_INTERVAL=60
DISK_WARN_PERCENT=90

# ── Host online check ────────────────────────────────────────────────────────
check_host_online() {
  local host="$1" label="${2:-$1}"
  if ssh -o ConnectTimeout=5 -o BatchMode=yes "$host" true 2>/dev/null; then
    alert_resolve "offline:${label}" "✅ *${label}* is back online."
    return 0
  else
    alert_fire "offline:${label}" "🔴 *${label}* is OFFLINE — cannot reach via SSH."
    return 1
  fi
}

# ── Disk space check ─────────────────────────────────────────────────────────
check_disk_space() {
  local mount="$1" label="${2:-$1}"
  local usage
  usage=$(df --output=pcent "$mount" 2>/dev/null | tail -1 | tr -d '% ')
  if [[ -z "$usage" ]]; then
    alert_fire "disk:${label}" "⚠️ Cannot read disk usage for *${label}* (\`${mount}\`)."
    return 1
  fi
  if (( usage >= DISK_WARN_PERCENT )); then
    alert_fire "disk:${label}" "💾 Disk *${label}* (\`${mount}\`) is at *${usage}%* — running out of space!"
    return 1
  else
    alert_resolve "disk:${label}" "✅ Disk *${label}* (\`${mount}\`) back to normal (*${usage}%*)."
    return 0
  fi
}

# ── Monitor loop (meant to run as background process) ────────────────────────
monitor_loop() {
  local last_disk_check=0
  log_info "Monitor started (ping=${MONITOR_PING_INTERVAL}s, disk=${MONITOR_DISK_INTERVAL}s)"

  while true; do
    local now
    now=$(date +%s)

    # -- Host online checks (every 30 s) --
    if [[ -d "$BACKUP_HOSTS_DIR" ]]; then
      local host_count=0
      for hcfg in "$BACKUP_HOSTS_DIR"/*.conf; do
        [[ -f "$hcfg" ]] || continue
        local htype haddr
        htype=$(cfg_get "$hcfg" type)
        haddr=$(cfg_get "$hcfg" address)
        local hlabel
        hlabel=$(basename "$hcfg" .conf)
        if [[ "$htype" == "ssh" && -n "$haddr" ]]; then
          # Limit concurrent SSH checks to avoid overwhelming the network
          if (( host_count >= 10 )); then
            wait
            host_count=0
          fi
          check_host_online "$haddr" "$hlabel" &
          host_count=$(( host_count + 1 ))
        fi
      done
      wait  # reap background pings
    fi

    # -- Disk space checks (every 60 s) --
    if (( now - last_disk_check >= MONITOR_DISK_INTERVAL )); then
      last_disk_check=$now
      local drives
      drives=$(cfg_get "$BACKUP_CONF_FILE" important_drives)
      if [[ -n "$drives" ]]; then
        local IFS=','
        for drive in $drives; do
          check_disk_space "$drive" "$drive"
        done
      fi
      # Also check main backup destination
      local dest
      dest=$(cfg_get "$BACKUP_CONF_FILE" backup_dest)
      if [[ -n "$dest" ]]; then
        check_disk_space "$dest" "backup-dest"
      fi
    fi

    sleep "$MONITOR_PING_INTERVAL"
  done
}
