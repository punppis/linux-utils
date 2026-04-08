#!/usr/bin/env bash
# shellcheck shell=bash
# Common helpers for backup-tool

# Exported via source — used by backup-tool and setup
# shellcheck disable=SC2034
BACKUP_TOOL_VERSION="1.0.0"

# ── Colors ───────────────────────────────────────────────────────────────────
COL_RESET="" COL_RED="" COL_GREEN="" COL_YELLOW="" COL_CYAN="" COL_BLUE=""
if [[ -t 2 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
  COL_RESET="\033[0m"; COL_RED="\033[31m"; COL_GREEN="\033[32m"
  COL_YELLOW="\033[33m"; COL_CYAN="\033[36m"; COL_BLUE="\033[34m"
fi

log_info()  { echo -e "${COL_BLUE}[INFO]${COL_RESET}  $(date '+%H:%M:%S') $*" >&2; }
log_ok()    { echo -e "${COL_GREEN}[OK]${COL_RESET}    $(date '+%H:%M:%S') $*" >&2; }
log_warn()  { echo -e "${COL_YELLOW}[WARN]${COL_RESET}  $(date '+%H:%M:%S') $*" >&2; }
log_error() { echo -e "${COL_RED}[ERROR]${COL_RESET} $(date '+%H:%M:%S') $*" >&2; }
log_step()  { echo -e "\n${COL_CYAN}[+]${COL_RESET} $*" >&2; }

# ── Config paths ─────────────────────────────────────────────────────────────
BACKUP_CONF_DIR="${BACKUP_CONF_DIR:-/etc/backup-tool}"
# shellcheck disable=SC2034
BACKUP_CONF_FILE="${BACKUP_CONF_DIR}/backup.conf"
BACKUP_HOSTS_DIR="${BACKUP_CONF_DIR}/hosts.d"
BACKUP_STATE_DIR="${BACKUP_STATE_DIR:-/var/lib/backup-tool}"
BACKUP_LOG_DIR="${BACKUP_LOG_DIR:-/var/log/backup-tool}"

ensure_dirs() {
  mkdir -p "$BACKUP_CONF_DIR" "$BACKUP_HOSTS_DIR" \
           "$BACKUP_STATE_DIR" "$BACKUP_LOG_DIR"
}

# ── Config helpers ───────────────────────────────────────────────────────────
# Read a key from an INI-style config file (key=value)
cfg_get() {
  local file="$1" key="$2" default="${3:-}"
  if [[ -f "$file" ]]; then
    local val
    val=$(grep -m1 "^${key}=" "$file" 2>/dev/null | cut -d'=' -f2- | sed 's/^[ "]*//;s/[ "]*$//')
    if [[ -n "$val" ]]; then
      echo "$val"
      return
    fi
  fi
  echo "$default"
}

# Write a key to an INI-style config file (upsert)
cfg_set() {
  local file="$1" key="$2" value="$3"
  mkdir -p "$(dirname "$file")"
  if [[ -f "$file" ]] && grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

# ── Misc ─────────────────────────────────────────────────────────────────────
require_cmd() {
  local cmd="$1" pkg="${2:-$1}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "'$cmd' is required but not found. Install it: apt-get install $pkg"
    return 1
  fi
}

ts_now() { date +%s; }

human_size() {
  local bytes="$1"
  if   (( bytes >= 1073741824 )); then echo "$(( bytes / 1073741824 ))G"
  elif (( bytes >= 1048576 ));    then echo "$(( bytes / 1048576 ))M"
  elif (( bytes >= 1024 ));       then echo "$(( bytes / 1024 ))K"
  else echo "${bytes}B"
  fi
}
