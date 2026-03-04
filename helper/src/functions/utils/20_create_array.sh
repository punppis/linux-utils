# Create bash array from input
# @cmd create_array Create a bash array from input.

create_array() {
  local separators=$'\n'
  local name=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --separators)
        separators="$2"
        shift 2
        ;;
      --name)
        name="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  local -a items=()
  read_items items "$separators" "$@"

  [ "${#items[@]}" -eq 0 ] && die "No input provided."

  local -a out=()
  local item
  for item in "${items[@]}"; do
    out+=("$(printf '%q' "$item")")
  done

  if [ -n "$name" ]; then
    printf '%s=(' "$name"
  else
    printf '('
  fi

  printf '%s ' "${out[@]}"
  printf ')\n'
}
