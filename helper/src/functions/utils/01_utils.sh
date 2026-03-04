# Shared utilities

is_tty() {
  [ -t 2 ]
}

color_enabled() {
  if [ -n "${NO_COLOR:-}" ]; then
    return 1
  fi
  if [ "${TERM:-dumb}" = "dumb" ]; then
    return 1
  fi
  is_tty
}

color_reset() { printf '\033[0m'; }
color_red() { printf '\033[31m'; }
color_green() { printf '\033[32m'; }
color_yellow() { printf '\033[33m'; }
color_blue() { printf '\033[34m'; }
color_magenta() { printf '\033[35m'; }
color_cyan() { printf '\033[36m'; }

colorize() {
  local color="$1"
  shift
  if color_enabled; then
    printf '%s%s%s' "$("color_${color}")" "$*" "$(color_reset)"
  else
    printf '%s' "$*"
  fi
}

log() {
  colorize cyan "$*" >&2
  printf '\n' >&2
}

log_warn() {
  colorize yellow "$*" >&2
  printf '\n' >&2
}

log_error() {
  colorize red "$*" >&2
  printf '\n' >&2
}

die() {
  log_error "Error: $*"
  exit 1
}

confirm_run() {
  local cmd_display="$*"
  log "About to run: $cmd_display"

  if [ -t 0 ] && [ -t 1 ]; then
    local reply=""
    printf 'Proceed? [Y/n] ' >&2
    read -r reply
    case "$reply" in
      n|N|no|NO)
        log_warn "Canceled"
        return 1
        ;;
    esac
  fi

  "$@"
}

is_alias_name() {
  local name="$1"
  local a
  for a in "${PROG_ALIASES[@]}"; do
    if [ "$name" = "$a" ]; then
      return 0
    fi
  done
  return 1
}

read_items() {
  local -n __out="$1"
  local separators="$2"
  shift 2

  local data=""
  if [ ! -t 0 ]; then
    data="$(cat)"
  fi

  if [ "$#" -gt 0 ]; then
    if [ -n "$data" ]; then
      data+=$'\n'
    fi
    data+="$*"
  fi

  data="$(printf "%s" "$data" | tr "$separators" '\n')"
  mapfile -t __out < <(
    printf "%s\n" "$data" \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
      | sed '/^$/d'
  )
}
