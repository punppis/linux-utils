# Arg parsing helper
# @cmd arg Extract option value from args (--long/-s).

arg() {
  local long="${1:-}"
  local short="${2:-}"
  shift 2 || true

  if [ -z "$long" ] || [ -z "$short" ]; then
    die "Usage: arg --long -s [--] [args...]"
  fi

  if [ "${1:-}" = "--" ]; then
    shift
  fi

  local -a args=()
  if [ "$#" -gt 0 ]; then
    args=("$@")
  else
    mapfile -t args < <(tr ' ' '\n' | sed '/^$/d')
  fi

  local i=0
  while [ $i -lt ${#args[@]} ]; do
    local token="${args[$i]}"
    case "$token" in
      ${long}=*|${short}=*)
        printf '%s\n' "${token#*=}"
        return 0
        ;;
      ${long}|${short})
        local next_index=$((i + 1))
        if [ $next_index -lt ${#args[@]} ]; then
          printf '%s\n' "${args[$next_index]}"
          return 0
        else
          die "Option '$token' requires a value"
        fi
        ;;
    esac
    i=$((i + 1))
  done

  return 1
}
