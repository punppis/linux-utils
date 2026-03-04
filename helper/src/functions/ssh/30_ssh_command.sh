# Run one or more commands on multiple hosts
# @cmd ssh-command Run commands on multiple hosts.

ssh_command_multi() {
  local -a commands=()
  local -a hosts=()

  local found_delim=0
  local arg
  for arg in "$@"; do
    if [ "$arg" = "--" ]; then
      found_delim=1
      continue
    fi
    if [ "$found_delim" -eq 0 ]; then
      commands+=("$arg")
    else
      hosts+=("$arg")
    fi
  done

  if [ "$found_delim" -eq 0 ]; then
    if [ ! -t 0 ]; then
      read_items hosts ", "
      commands=("$@")
    else
      if [ "$#" -lt 3 ]; then
        die "Usage: ssh-command <cmd1> <cmd2> <host...> (or use --)"
      fi
      commands=("${@:1:2}")
      hosts=("${@:3}")
    fi
  fi

  [ "${#commands[@]}" -eq 0 ] && die "No commands provided."
  [ "${#hosts[@]}" -eq 0 ] && die "No hosts provided."

  local h c
  for h in "${hosts[@]}"; do
    for c in "${commands[@]}"; do
      log "[$h] $c"
      ssh "$h" "$c"
    done
  done
}
