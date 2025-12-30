#!/usr/bin/env bash
set -euo pipefail

# Common helpers for init scripts. Can be sourced by other helpers.

log_step() {
  echo -e "\n[+] $*"
}

log_info() {
  echo -e "[.] $*"
}

log_warn() {
  echo -e "[!] $*" >&2
}

log_done() {
  echo -e "[✓] $*"
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    log_warn "This script must run as root (try: sudo $0)."
    exit 1
  fi
}

resolve_target_user() {
  local user=${TARGET_USER:-${SUDO_USER:-}}
  if [[ -z "$user" || "$user" == "root" ]]; then
    user=${SUDO_USER:-}
  fi
  if [[ -z "$user" || "$user" == "root" ]]; then
    if [[ -t 0 ]]; then
      read -rp "Enter the non-root username to configure: " user
    else
      log_warn "TARGET_USER not set and no TTY available to prompt."
      exit 1
    fi
  fi
  if ! id -u "$user" >/dev/null 2>&1; then
    log_warn "User '$user' does not exist."
    exit 1
  fi
  echo "$user"
}

ensure_group() {
  local group="$1"
  if ! getent group "$group" >/dev/null; then
    groupadd "$group"
    log_info "Created group: $group"
  fi
}

add_user_to_group() {
  local user="$1" group="$2"
  if id -nG "$user" | grep -qw "$group"; then
    return
  fi
  usermod -aG "$group" "$user"
  log_info "Added $user to $group"
}

append_sudoers_nopasswd_group() {
  local group="$1" entry="%${group} ALL=(ALL) NOPASSWD:ALL"
  local file="/etc/sudoers.d/${group}-nopasswd"
  if [[ -f "$file" ]] && grep -Fxq "$entry" "$file"; then
    return
  fi
  echo "$entry" >"$file"
  chmod 440 "$file"
  log_info "Granted passwordless sudo to group: $group"
}

apt_update() {
  log_step "Updating apt package lists..."
  apt-get update -y
}

apt_upgrade() {
  log_step "Upgrading packages..."
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
}

apt_full_upgrade() {
  log_step "Upgrading distro (full-upgrade)..."
  DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
}

apt_install_packages() {
  local packages=("$@")
  if [[ ${#packages[@]} -eq 0 ]]; then
    return
  fi
  log_step "Installing packages: ${packages[*]}"
  DEBIAN_FRONTEND=noninteractive apt-get install -fmqy "${packages[@]}"
}

install_docker_engine() {
  if command -v docker >/dev/null 2>&1; then
    log_info "Docker already present; skipping install."
    return
  fi
  log_step "Installing Docker using get.docker.com..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
}

configure_nano() {
  local target_user="$1"; shift || true
  local target_home
  target_home=$(eval echo "~${target_user}")
  local nanorc="${target_home}/.nanorc"
  mkdir -p "$target_home"
  cat >"$nanorc" <<'EOF'
set tabsize 4
set tabstospaces
set linenumbers
set softwrap
include "/usr/share/nano/*.nanorc"
EOF
  chown "$target_user":"$target_user" "$nanorc"
  log_info "Configured nano defaults for ${target_user} (tabs=4, syntax includes)."
}

ensure_user_shell_block() {
  # Usage: ensure_user_shell_block <user> <block_id> <multiline_block>
  local target_user="$1" block_id="$2" block_content="$3"
  local target_home shellfile start_marker end_marker
  target_home=$(eval echo "~${target_user}")
  shellfile="${target_home}/.bash_aliases"
  start_marker="# BEGIN ${block_id}"
  end_marker="# END ${block_id}"

  mkdir -p "$target_home"
  touch "$shellfile"

  # Remove existing block with same id (idempotent update)
  local start_escaped="${start_marker//\//\\/}"
  local end_escaped="${end_marker//\//\\/}"
  sed -i "/^${start_escaped}$/,/^${end_escaped}$/d" "$shellfile"

  {
    echo "$start_marker"
    echo "$block_content"
    echo "$end_marker"
  } >>"$shellfile"

  chown "$target_user":"$target_user" "$shellfile"
  log_info "Updated shell aliases/functions block '${block_id}' for ${target_user}."
}

prompt_additional_packages() {
  local extra_input="${EXTRA_PACKAGES:-}"
  if [[ -n "$extra_input" ]]; then
    echo "$extra_input"
    return
  fi
  if [[ -t 0 ]]; then
    read -rp "Enter extra packages to install (space-separated, or leave blank): " extra_input
    echo "$extra_input"
  fi
}

summary_line() {
  local items=("$@")
  local joined="${items[*]}"
  echo "Installed packages: ${joined}."
}

maybe_reboot_prompt() {
  local default_ans="n" prompt="Reboot now? [y/N]: "
  if [[ "${AUTO_REBOOT:-}" =~ ^(1|y|Y|yes|YES)$ ]]; then
    prompt="AUTO_REBOOT set; rebooting in 3 seconds..."
    log_step "$prompt"
    sleep 3
    reboot
  fi
  if [[ -t 0 ]]; then
    read -rp "$prompt" answer
    if [[ "$answer" =~ ^(y|Y|yes|YES)$ ]]; then
      reboot
    fi
  else
    log_info "Skipping reboot prompt (no TTY)."
  fi
}
