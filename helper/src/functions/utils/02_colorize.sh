# Colorize command
# @cmd colorize Colorize text output.

colorize_cmd() {
  local color="${1:-}"
  shift || true

  if [ -z "$color" ]; then
    die "Usage: colorize <color> <text>"
  fi

  colorize "$color" "$*"
  printf '\n'
}
