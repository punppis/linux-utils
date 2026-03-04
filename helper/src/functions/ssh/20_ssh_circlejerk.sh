# ssh-copy-id between all hosts
# @cmd ssh-circlejerk Copy SSH keys between all hosts.

ssh_circlejerk() {
  local dry_run=0
  if [ "${1:-}" = "--dry-run" ]; then
    dry_run=1
    shift
  fi

  local -a hosts=()
  read_items hosts ", " "$@"

  [ "${#hosts[@]}" -lt 2 ] && die "Need at least 2 hosts."

  local src dst cmd
  for src in "${hosts[@]}"; do
    for dst in "${hosts[@]}"; do
      [ "$src" = "$dst" ] && continue
      cmd="ssh-copy-id -o StrictHostKeyChecking=accept-new $dst"
      if [ "$dry_run" -eq 1 ]; then
        log "[dry-run] ssh $src \"$cmd\""
      else
        log "[$src -> $dst]"
        ssh "$src" "$cmd"
      fi
    done
  done
}
