#!/usr/bin/env bash
set -euo pipefail

# Curl|bash bootstrapper for linux-utils init-machine.
# Example:
#   curl -fsSL https://raw.githubusercontent.com/punppis/linux-utils/refs/heads/main/init.sh | bash

REPO_URL=${REPO_URL:-https://github.com/punpp/linux-utils.git}
REPO_BRANCH=${REPO_BRANCH:-main}
TARGET_DIR=${TARGET_DIR:-~/linux-utils}
INIT_SCRIPT=${INIT_SCRIPT:-scripts/init-machine.sh}

log() { echo "[init] $*"; }
warn() { echo "[init][warn] $*" >&2; }

gain_privilege() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    SUDO=""
  elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    warn "sudo not found and not running as root; attempting to continue without sudo (may fail)."
    SUDO=""
  fi
}

apt_install_git() {
  if command -v git >/dev/null 2>&1; then
    return
  fi
  log "Installing git..."
  $SUDO apt-get -fmqy update -y
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y git ca-certificates
}

clone_or_update_repo() {
  if [[ -d "$TARGET_DIR/.git" ]]; then
    log "Repository already present at $TARGET_DIR; pulling latest ($REPO_BRANCH)..."
    (cd "$TARGET_DIR" && git fetch --all && git checkout "$REPO_BRANCH" && git pull --ff-only)
  else
    log "Cloning $REPO_URL (branch: $REPO_BRANCH) to $TARGET_DIR..."
    $SUDO mkdir -p "$TARGET_DIR"
    $SUDO chown "${SUDO_USER:-${USER}}":"${SUDO_USER:-${USER}}" "$TARGET_DIR"
    git clone --branch "$REPO_BRANCH" "$REPO_URL" "$TARGET_DIR"
  fi
}

run_init_machine() {
  local script_path="$TARGET_DIR/$INIT_SCRIPT"
  if [[ ! -x "$script_path" ]]; then
    if [[ -f "$script_path" ]]; then
      $SUDO chmod +x "$script_path"
    else
      warn "Init script not found at $script_path"
      exit 1
    fi
  fi
  log "Running init script..."
  # Pass through common env knobs if set
  TARGET_USER="${TARGET_USER:-}" \
  EXTRA_PACKAGES="${EXTRA_PACKAGES:-}" \
  AUTO_REBOOT="${AUTO_REBOOT:-}" \
  $SUDO "$script_path"
}

main() {
  gain_privilege
  apt_install_git
  clone_or_update_repo
  run_init_machine
  log "Bootstrap complete."
}

main "$@"
