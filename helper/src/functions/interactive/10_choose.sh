# Choose helper
# @cmd choose Interactively choose an option.

choose() {
  local default=""
  local multi=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --default|-d)
        default="$2"
        shift 2
        ;;
      --multi|-m)
        multi=1
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  local -a items=()

  if [ "$#" -gt 0 ]; then
    items=("$@")
  else
    mapfile -t items < <(sed '/^$/d')
  fi

  if [ "${#items[@]}" -eq 0 ]; then
    die "No options provided"
  fi

  local -a clean_items=()
  local item
  for item in "${items[@]}"; do
    if [[ "$item" == *":default" ]]; then
      local stripped="${item%:default}"
      if [ -z "$default" ]; then
        default="$stripped"
      fi
      clean_items+=("$stripped")
    else
      clean_items+=("$item")
    fi
  done

  items=("${clean_items[@]}")

  if [ -z "$default" ]; then
    default="${items[0]}"
  fi

  if [ ! -t 0 ] || [ ! -t 1 ]; then
    if [ -n "$default" ]; then
      printf '%s\n' "$default"
      return 0
    fi
    if [ "$multi" -eq 1 ]; then
      printf '%s\n' "${items[@]}"
      return 0
    fi
    die "No TTY available for selection"
  fi

  log "Choose an option:"
  local i
  for i in "${!items[@]}"; do
    local idx=$((i + 1))
    if [ "${items[$i]}" = "$default" ]; then
      printf '  %d) %s (default)\n' "$idx" "${items[$i]}" >&2
    else
      printf '  %d) %s\n' "$idx" "${items[$i]}" >&2
    fi
  done

  if [ "$multi" -eq 1 ]; then
    printf 'Select one or more (e.g. 1 3 or 1,3) [1-%d] (default: %s): ' "${#items[@]}" "$default" >&2
  else
    printf 'Select [1-%d] (default: %s): ' "${#items[@]}" "$default" >&2
  fi

  local selection=""
  read -r selection

  if [ -z "$selection" ]; then
    printf '%s\n' "$default"
    return 0
  fi

  if [ "$multi" -eq 1 ]; then
    selection="$(printf '%s' "$selection" | tr ',' ' ')"
    local idx
    for idx in $selection; do
      if ! [[ "$idx" =~ ^[0-9]+$ ]]; then
        die "Invalid selection"
      fi
      if [ "$idx" -lt 1 ] || [ "$idx" -gt "${#items[@]}" ]; then
        die "Selection out of range"
      fi
      printf '%s\n' "${items[$((idx - 1))]}"
    done
    return 0
  fi

  if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
    die "Invalid selection"
  fi

  if [ "$selection" -lt 1 ] || [ "$selection" -gt "${#items[@]}" ]; then
    die "Selection out of range"
  fi

  printf '%s\n' "${items[$((selection - 1))]}"
}
