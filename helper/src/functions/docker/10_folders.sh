# Docker compose folders
# @cmd docker List compose project folders (docker folders all).

docker_folders_all() {
  command -v docker >/dev/null 2>&1 || die "docker not found"

  local -a ids=()
  mapfile -t ids < <(docker ps -q)

  if [ "${#ids[@]}" -eq 0 ]; then
    log "No running containers."
    return 0
  fi

  local id
  local -a folders=()
  for id in "${ids[@]}"; do
    local wdir
    wdir="$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "$id" 2>/dev/null || true)"
    if [ -n "$wdir" ] && [ "$wdir" != "<no value>" ]; then
      folders+=("$wdir")
    else
      local name
      name="$(docker inspect -f '{{ .Name }}' "$id" 2>/dev/null | sed 's#^/##')"
      log "non-compose: $name"
    fi
  done

  if [ "${#folders[@]}" -gt 0 ]; then
    printf "%s\n" "${folders[@]}" | sort -u
  fi
}
