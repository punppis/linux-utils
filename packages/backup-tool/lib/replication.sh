#!/usr/bin/env bash
# shellcheck shell=bash
# Replication — copy important backups to every important drive.
# Main copy stays uncompressed (for fast rsync).  Replicas are compressed.

# ── Replicate a directory to a drive ─────────────────────────────────────────
replicate_to_drive() {
  local src="$1" drive="$2" label="$3"
  local dest="${drive}/backup-replicas/${label}"
  mkdir -p "$dest"

  log_info "Replicating $label -> $dest"
  if ! rsync -a --delete "$src/" "$dest/" 2>&1; then
    log_error "Replication failed: $src -> $dest"
    alert_fire "replicate:${label}:${drive}" \
      "❌ Replication failed for \`${label}\` to \`${drive}\`"
    return 1
  fi
  alert_resolve "replicate:${label}:${drive}" \
    "✅ Replication recovered for \`${label}\` to \`${drive}\`"
  return 0
}

# ── Compress a replica directory in-place ────────────────────────────────────
compress_replica() {
  local dir="$1"
  local archive="${dir}.tar.gz"
  [[ -d "$dir" ]] || return 0

  log_info "Compressing replica: $dir"
  if tar -czf "$archive" -C "$(dirname "$dir")" "$(basename "$dir")" 2>&1; then
    rm -rf "$dir"
    log_ok "Compressed: $archive"
  else
    log_warn "Compression failed for $dir — keeping uncompressed copy"
  fi
}

# ── Replicate all important folders to all important drives ──────────────────
replicate_important() {
  local backup_dest
  backup_dest=$(cfg_get "$BACKUP_CONF_FILE" backup_dest "/backup")
  local important_folders
  important_folders=$(cfg_get "$BACKUP_CONF_FILE" important_folders)
  local important_drives
  important_drives=$(cfg_get "$BACKUP_CONF_FILE" important_drives)

  if [[ -z "$important_folders" ]]; then
    log_info "No important folders configured — skipping replication"
    return 0
  fi
  if [[ -z "$important_drives" ]]; then
    log_info "No important drives configured — skipping replication"
    return 0
  fi

  local IFS=','
  local errors=0
  for folder in $important_folders; do
    folder=$(echo "$folder" | xargs)
    [[ -z "$folder" ]] && continue

    # folder is relative to backup_dest, e.g. "myhost/var_data"
    local src="${backup_dest}/${folder}/latest"
    if [[ ! -d "$src" ]]; then
      log_warn "Important folder latest snapshot not found: $src"
      continue
    fi

    for drive in $important_drives; do
      drive=$(echo "$drive" | xargs)
      [[ -z "$drive" ]] && continue
      if [[ ! -d "$drive" ]]; then
        log_warn "Important drive not mounted: $drive"
        alert_fire "drive:${drive}" "⚠️ Important drive \`${drive}\` not mounted"
        errors=$(( errors + 1 ))
        continue
      fi

      local safe_label="${folder//\//_}"
      if replicate_to_drive "$src" "$drive" "$safe_label"; then
        compress_replica "${drive}/backup-replicas/${safe_label}"
      else
        errors=$(( errors + 1 ))
      fi
    done
  done

  if (( errors > 0 )); then
    log_warn "Replication finished with $errors error(s)"
    return 1
  fi
  log_ok "All important folders replicated and compressed"
  return 0
}
