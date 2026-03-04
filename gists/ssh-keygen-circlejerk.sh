#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# get_input
# Emits either stdin or args
# -------------------------
get_input() {
  if [[ ! -t 0 ]]; then
    cat -
  else
    printf '%s\n' "$@"
  fi
}

# -------------------------
# parse_hosts
# Reads stdin
# Outputs one cleaned host per line
# -------------------------
parse_hosts() {
  tr ',[:space:]' '\n' |
  grep -v '^$'
}

# mapfile: Read lines from the standard input into an indexed array variable
mapfile -t HOSTS < <(get_input "$@" | parse_hosts)

if (( ${#HOSTS[@]} == 0 )); then
  echo "No hosts provided."
  exit 1
fi

printf 'Parsed hosts:\n'
printf '  - %s\n' "${HOSTS[@]}"