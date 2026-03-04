# Path helpers
# @cmd get_current_script Print the current script path.

get_current_script() {
  local src="${BASH_SOURCE[0]}"

  if command -v readlink >/dev/null 2>&1; then
    local resolved
    resolved="$(readlink -f "$src" 2>/dev/null || true)"
    if [ -n "$resolved" ]; then
      printf '%s\n' "$resolved"
      return 0
    fi
  fi

  if [[ "$src" != /* ]]; then
    src="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
  fi

  printf '%s\n' "$src"
}

# @cmd get_path Print directory path(s) for input.
get_path() {
  local -a items=()

  if [ ! -t 0 ]; then
    mapfile -t items < <(sed '/^$/d')
  else
    items=("$@")
  fi

  [ "${#items[@]}" -eq 0 ] && die "No input provided."

  local item
  for item in "${items[@]}"; do
    if command -v dirname >/dev/null 2>&1; then
      dirname -- "$item"
    else
      printf '%s\n' "${item%/*}"
    fi
  done
}
