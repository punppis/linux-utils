#!/usr/bin/env bash
# shellcheck shell=bash
# Backup logic — rsync for SSH/bind-mount paths, docker cp for docker volumes.

# ── rsync-based backup (SSH hosts or local/bind-mount paths) ─────────────────
backup_rsync() {
  local src="$1" dest="$2" link_dest="${3:-}"
  mkdir -p "$dest"

  local rsync_opts=( -a --delete --info=progress2 --timeout=300 )
  if [[ -n "$link_dest" && -d "$link_dest" ]]; then
    rsync_opts+=( --link-dest="$link_dest" )
  fi

  log_info "rsync: $src -> $dest"
  if ! rsync "${rsync_opts[@]}" "$src" "$dest/" 2>&1; then
    log_error "rsync failed: $src -> $dest"
    alert_fire "rsync:${src}" "❌ rsync failed for \`${src}\`"
    return 1
  fi
  alert_resolve "rsync:${src}" "✅ rsync recovered for \`${src}\`"
  return 0
}

# ── Docker volume backup (cp via temp container) ─────────────────────────────
backup_docker_volume() {
  local volume="$1" dest="$2" host="${3:-}"
  mkdir -p "$dest"

  local docker_cmd="docker"
  if [[ -n "$host" ]]; then
    docker_cmd="docker -H ssh://${host}"
  fi

  local tmp_container
  tmp_container="backup-vol-$$-$(date +%s)"
  log_info "docker volume backup: $volume -> $dest"

  # Create a temporary container that mounts the volume
  if ! $docker_cmd run --rm -d --name "$tmp_container" \
       -v "${volume}:/volume:ro" alpine:latest tail -f /dev/null >/dev/null 2>&1; then
    log_error "Failed to start temp container for volume $volume"
    alert_fire "dockervol:${volume}" "❌ Cannot backup docker volume \`${volume}\`"
    return 1
  fi

  # Copy data out
  if ! $docker_cmd cp "${tmp_container}:/volume/." "$dest/" 2>&1; then
    log_error "docker cp failed for volume $volume"
    $docker_cmd rm -f "$tmp_container" >/dev/null 2>&1 || true
    alert_fire "dockervol:${volume}" "❌ docker cp failed for volume \`${volume}\`"
    return 1
  fi

  $docker_cmd rm -f "$tmp_container" >/dev/null 2>&1 || true
  alert_resolve "dockervol:${volume}" "✅ docker volume \`${volume}\` backup recovered"
  log_ok "docker volume $volume backed up"
  return 0
}

# ── Back up a single host (all its paths) ────────────────────────────────────
# Reads host config file and runs appropriate backup method for each path.
# Creates timestamped snapshot directories, links to "latest" for incremental.
backup_host() {
  local host_conf="$1"
  local host_label
  host_label=$(basename "$host_conf" .conf)

  local host_type host_address
  host_type=$(cfg_get "$host_conf" type)        # ssh | docker
  host_address=$(cfg_get "$host_conf" address)   # user@host or docker node addr

  local paths
  paths=$(cfg_get "$host_conf" paths)            # comma-separated
  [[ -z "$paths" ]] && { log_warn "No paths for host $host_label"; return 0; }

  local backup_dest
  backup_dest=$(cfg_get "$BACKUP_CONF_FILE" backup_dest "/backup")

  local ts
  ts=$(date +%Y%m%d-%H%M%S)

  local IFS=','
  local path_errors=0
  for p in $paths; do
    p=$(echo "$p" | xargs)   # trim whitespace
    [[ -z "$p" ]] && continue

    local safe_path="${p//\//_}"
    safe_path="${safe_path#_}"
    local host_dest="${backup_dest}/${host_label}/${safe_path}"
    local snap_dir="${host_dest}/${ts}"
    local latest_link="${host_dest}/latest"

    local volume_type
    volume_type=$(cfg_get "$host_conf" "volume_type_${safe_path}" "")
    # If not set per-path, fall back to host-level default
    [[ -z "$volume_type" ]] && volume_type="$host_type"

    case "$volume_type" in
      ssh)
        local link_dest=""
        [[ -L "$latest_link" ]] && link_dest=$(readlink -f "$latest_link")
        if backup_rsync "${host_address}:${p}/" "$snap_dir" "$link_dest"; then
          ln -sfn "$snap_dir" "$latest_link"
        else
          path_errors=$(( path_errors + 1 ))
        fi
        ;;
      docker)
        if backup_docker_volume "$p" "$snap_dir" "$host_address"; then
          ln -sfn "$snap_dir" "$latest_link"
        else
          path_errors=$(( path_errors + 1 ))
        fi
        ;;
      *)
        log_error "Unknown volume type '$volume_type' for $host_label:$p"
        path_errors=$(( path_errors + 1 ))
        ;;
    esac
  done

  return "$path_errors"
}

# ── Run backups for all configured hosts ─────────────────────────────────────
backup_all() {
  local errors=0
  if [[ ! -d "$BACKUP_HOSTS_DIR" ]]; then
    log_warn "No hosts directory at $BACKUP_HOSTS_DIR"
    return 0
  fi

  for hcfg in "$BACKUP_HOSTS_DIR"/*.conf; do
    [[ -f "$hcfg" ]] || continue
    local label
    label=$(basename "$hcfg" .conf)
    log_step "Backing up host: $label"
    if ! backup_host "$hcfg"; then
      errors=$(( errors + 1 ))
    fi
  done

  if (( errors > 0 )); then
    log_warn "$errors host(s) had errors"
    return 1
  fi
  log_ok "All hosts backed up successfully"
  return 0
}
