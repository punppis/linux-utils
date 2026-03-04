# List commands
# @cmd commands List available commands with descriptions.

list_commands() {
  local script
  script="$(get_current_script)"

  local entries
  entries="$(grep -E '^# @cmd ' "$script" || true)"

  if [ -z "$entries" ]; then
    die "No command metadata found"
  fi

  declare -A descs
  while IFS= read -r line; do
    line="${line#\# @cmd }"
    local cmd="${line%% *}"
    local desc="${line#* }"
    if [ "$cmd" = "$desc" ]; then
      desc=""
    fi
    descs["$cmd"]="$desc"
  done <<<"$entries"

  local -a groups=(
    "utils"
    "interactive"
    "fs"
    "ssh"
    "docker"
    "data"
    "compress"
    "transform"
  )

  declare -A group_cmds
  group_cmds[utils]="create_array colorize commands help install autocomplete"
  group_cmds[interactive]="choose"
  group_cmds[fs]="path file"
  group_cmds[ssh]="ssh-circlejerk ssh-copy-id ssh-command"
  group_cmds[docker]="docker"
  group_cmds[data]="archive base64 compress decompress decrypt"
  group_cmds[compress]="compress decompress"
  group_cmds[transform]="encrypt decrypt base64 hash"

  local group
  for group in "${groups[@]}"; do
    printf '%s\n' "[$group]"
    printf '%-22s %s\n' "COMMAND" "DESCRIPTION"
    printf '%-22s %s\n' "-------" "-----------"
    local cmd
    for cmd in ${group_cmds[$group]}; do
      printf '%-22s %s\n' "$cmd" "${descs[$cmd]}"
    done
    printf '\n'
  done
}
