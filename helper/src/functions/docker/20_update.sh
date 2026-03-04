# Docker update helpers
# @cmd docker Update docker compose projects (folders/update/update_all).

docker_update() {
  confirm_run docker compose up -d --pull always --remove-orphans --force-recreate
}

docker_update_all() {
  local -a folders=()
  mapfile -t folders < <(docker_folders_all)

  if [ "${#folders[@]}" -eq 0 ]; then
    log "No docker compose folders found."
    return 0
  fi

  local -a selected=()
  mapfile -t selected < <(choose --multi "${folders[@]}")

  if [ "${#selected[@]}" -eq 0 ]; then
    log_warn "No folders selected."
    return 0
  fi

  local path
  for path in "${selected[@]}"; do
    confirm_run bash -c 'cd "$1" && docker compose up -d --pull always --remove-orphans --force-recreate' _ "$path"
  done
}
