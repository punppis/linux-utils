# ssh-copy-id for multiple hosts
# @cmd ssh-copy-id Run ssh-copy-id on multiple hosts.

ssh_copy_id_multi() {
  local -a hosts=()
  read_items hosts ", " "$@"

  [ "${#hosts[@]}" -eq 0 ] && die "No hosts provided."

  local h
  for h in "${hosts[@]}"; do
    log "ssh-copy-id -> $h"
    ssh-copy-id -o StrictHostKeyChecking=accept-new "$h"
  done
}
