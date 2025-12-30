#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/init_common.sh
source "${SCRIPT_DIR}/lib/init_common.sh"

log_step "Setting up fresh linux install..."
require_root

target_user=$(resolve_target_user)
log_info "Target user: ${target_user}"

apt_update
apt_upgrade
apt_full_upgrade

BASE_PACKAGES=(nano jq net-tools iftop btop htop iotop glances unzip wget curl ca-certificates gnupg lsb-release python3 python3-pip apt-transport-https software-properties-common)
extra_pkgs=$(prompt_additional_packages)
if [[ -n "${extra_pkgs:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA_PACKAGES_ARR=($extra_pkgs)
  PACKAGES=("${BASE_PACKAGES[@]}" "${EXTRA_PACKAGES_ARR[@]}")
else
  PACKAGES=("${BASE_PACKAGES[@]}")
fi

apt_install_packages "${PACKAGES[@]}"
log_done "Installed packages: ${PACKAGES[*]}"

# Configure nano for the target user
configure_nano "$target_user"

# Superuser group for passwordless sudo
SUPERUSER_GROUP="superuser"
ensure_group "$SUPERUSER_GROUP"
add_user_to_group "$target_user" "$SUPERUSER_GROUP"
append_sudoers_nopasswd_group "$SUPERUSER_GROUP"
log_done "Gave ${target_user} superuser (passwordless sudo) access via group '${SUPERUSER_GROUP}'."

# Docker install and group membership
install_docker_engine
ensure_group docker
add_user_to_group "$target_user" docker
if [[ -S /var/run/docker.sock ]]; then
  chmod g+rw /var/run/docker.sock
fi
log_done "Gave ${target_user} docker access."

log_done "Base setup complete."
maybe_reboot_prompt
