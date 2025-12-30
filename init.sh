#!/usr/bin/env bash
set -euo pipefail

# Curl|bash bootstrapper for linux-utils init-machine.
# Example:
#   curl -fsSL https://raw.githubusercontent.com/punppis/linux-utils/refs/heads/main/init.sh | bash

REPO_NAME=${REPO_NAME:-punppis/linux-utils}
REPO_URL=${REPO_URL:-https://github.com/$REPO_NAME.git}
REPO_URL_SSH=${REPO_URL_SSH:-git@github.com:$REPO_NAME.git}
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
  local https_url="$REPO_URL" ssh_url="${REPO_URL_SSH}"
  if [[ -z "$ssh_url" && "$https_url" =~ ^https?://([^/]+)/(.*)$ ]]; then
    ssh_url="git@${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
  fi
  local owner="${SUDO_USER:-${USER}}"

  if [[ -d "$TARGET_DIR/.git" ]]; then
    log "Repository already present at $TARGET_DIR; pulling latest ($REPO_BRANCH)..."
    if ! (cd "$TARGET_DIR" && git fetch --all && git checkout "$REPO_BRANCH" && git pull --ff-only); then
      warn "Fetch/pull failed; consider checking network or credentials."
      return 1
    fi
  else
    local tmpdir
    tmpdir=$(mktemp -d)
    local cloned=0

    if [[ -n "$ssh_url" ]]; then
      log "Cloning via SSH: $ssh_url (branch: $REPO_BRANCH)..."
      if git clone --branch "$REPO_BRANCH" "$ssh_url" "$tmpdir"; then
        cloned=1
      else
        warn "SSH clone failed; falling back to HTTPS."
      fi
    fi

    if [[ $cloned -eq 0 ]]; then
      log "Cloning via HTTPS: $https_url (branch: $REPO_BRANCH)..."
      if ! git clone --branch "$REPO_BRANCH" "$https_url" "$tmpdir"; then
        warn "HTTPS clone failed; aborting."
        rm -rf "$tmpdir"
        return 1
      fi
    fi

    $SUDO rm -rf "$TARGET_DIR"
    $SUDO mkdir -p "$(dirname "$TARGET_DIR")"
    $SUDO mv "$tmpdir" "$TARGET_DIR"
    $SUDO chown -R "$owner":"$owner" "$TARGET_DIR"
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
