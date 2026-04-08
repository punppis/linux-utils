#!/usr/bin/env bash
# shellcheck shell=bash
# Retention — time-based and size-based TTL per host/path.
#
# Each host config can specify:
#   retention_days=30          (delete snapshots older than N days)
#   retention_max_size=10G     (keep total size under limit, oldest first)
#
# These can also be overridden per-path with:
#   retention_days_<safe_path>=7
#   retention_max_size_<safe_path>=2G

# Parse human size string (e.g. 10G, 500M) to bytes
parse_size() {
  local s="${1^^}"
  local num="${s//[^0-9.]/}"
  case "$s" in
    *T) awk "BEGIN{printf \"%d\", $num * 1099511627776}"; ;;
    *G) awk "BEGIN{printf \"%d\", $num * 1073741824}"; ;;
    *M) awk "BEGIN{printf \"%d\", $num * 1048576}"; ;;
    *K) awk "BEGIN{printf \"%d\", $num * 1024}"; ;;
    *)  echo "${num%.*}"; ;;
  esac
}

# Get total size of a directory in bytes
dir_size_bytes() {
  du -sb "$1" 2>/dev/null | awk '{print $1}'
}

# Apply retention to a single path directory (contains timestamped snapshots).
# $1 = path directory (e.g. /backup/myhost/var_data)
# $2 = max age in days (0 = unlimited)
# $3 = max size string (empty = unlimited)
apply_retention() {
  local path_dir="$1" max_days="${2:-0}" max_size_str="${3:-}"

  [[ -d "$path_dir" ]] || return 0

  # Enumerate snapshots (directories named YYYYMMDD-HHMMSS), sorted oldest first
  local snaps=()
  while IFS= read -r d; do
    [[ -d "$d" ]] && snaps+=("$d")
  done < <(find "$path_dir" -mindepth 1 -maxdepth 1 -type d \
           -regextype posix-extended -regex '.*/[0-9]{8}-[0-9]{6}' 2>/dev/null | sort)

  if [[ ${#snaps[@]} -le 1 ]]; then
    return 0   # always keep at least one snapshot
  fi

  local removed=0

  # ── Time-based retention ──
  if (( max_days > 0 )); then
    local cutoff
    cutoff=$(date -d "${max_days} days ago" +%s 2>/dev/null || date -v-"${max_days}"d +%s 2>/dev/null || echo "")
    if [[ -z "$cutoff" || "$cutoff" == "0" ]]; then
      log_warn "Cannot compute cutoff date — skipping time-based retention"
      return 0
    fi
    local keep=()
    local total_count=${#snaps[@]}
    local kept_count=0
    for snap in "${snaps[@]}"; do
      local snap_name
      snap_name=$(basename "$snap")
      # Parse YYYYMMDD-HHMMSS
      local snap_ts
      snap_ts=$(date -d "${snap_name:0:4}-${snap_name:4:2}-${snap_name:6:2} ${snap_name:9:2}:${snap_name:11:2}:${snap_name:13:2}" +%s 2>/dev/null || echo 0)
      if (( snap_ts == 0 )); then
        log_warn "Cannot parse timestamp for snapshot $snap — skipping"
        keep+=("$snap")
        kept_count=$(( kept_count + 1 ))
        continue
      fi
      local remaining=$(( total_count - removed - kept_count ))
      if (( snap_ts > 0 && snap_ts < cutoff && remaining > 1 )); then
        log_info "Retention (age): removing $snap"
        rm -rf "$snap"
        removed=$(( removed + 1 ))
      else
        keep+=("$snap")
        kept_count=$(( kept_count + 1 ))
      fi
    done
    if [[ ${#keep[@]} -gt 0 ]]; then
      snaps=("${keep[@]}")
    else
      snaps=()
    fi
  fi

  # ── Size-based retention ──
  if [[ -n "$max_size_str" ]]; then
    local max_bytes
    max_bytes=$(parse_size "$max_size_str")
    local total
    total=$(dir_size_bytes "$path_dir")

    while (( total > max_bytes && ${#snaps[@]} > 1 )); do
      local oldest="${snaps[0]}"
      local oldest_size
      oldest_size=$(dir_size_bytes "$oldest")
      log_info "Retention (size): removing $oldest ($(human_size "$oldest_size"))"
      rm -rf "$oldest"
      snaps=("${snaps[@]:1}")
      total=$(( total - oldest_size ))
      removed=$(( removed + 1 ))
    done
  fi

  if (( removed > 0 )); then
    log_info "Retention: removed $removed snapshot(s) from $path_dir"
  fi
}

# Apply retention to all hosts/paths based on their config
retention_all() {
  local backup_dest
  backup_dest=$(cfg_get "$BACKUP_CONF_FILE" backup_dest "/backup")

  for hcfg in "$BACKUP_HOSTS_DIR"/*.conf; do
    [[ -f "$hcfg" ]] || continue
    local label
    label=$(basename "$hcfg" .conf)
    local default_days default_size
    default_days=$(cfg_get "$hcfg" retention_days 0)
    default_size=$(cfg_get "$hcfg" retention_max_size "")

    local paths
    paths=$(cfg_get "$hcfg" paths)
    [[ -z "$paths" ]] && continue

    local IFS=','
    for p in $paths; do
      p=$(echo "$p" | xargs)
      [[ -z "$p" ]] && continue
      local safe_path="${p//\//_}"
      safe_path="${safe_path#_}"
      local path_dir="${backup_dest}/${label}/${safe_path}"

      local days size
      days=$(cfg_get "$hcfg" "retention_days_${safe_path}" "$default_days")
      size=$(cfg_get "$hcfg" "retention_max_size_${safe_path}" "$default_size")

      apply_retention "$path_dir" "$days" "$size"
    done
  done
}
