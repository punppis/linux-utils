#!/usr/bin/env bash
set -euo pipefail

: "${ROOT_DIR:?ROOT_DIR is required}"
: "${APP:?APP is required}"
: "${TMP_DIR:?TMP_DIR is required}"

fail() {
  printf '%sFAIL:%s %s\n' "$(color red)" "$(color reset)" "$*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [ "$expected" != "$actual" ]; then
    printf 'FAIL: %s\nExpected: %s\nActual:   %s\n' "$msg" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_int() {
  local value="$1"
  local msg="$2"
  if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
    printf 'FAIL: %s\nExpected integer, got: %s\n' "$msg" "$value" >&2
    exit 1
  fi
}

run_cmd() {
  bash "$APP" "$@"
}

skip() {
  printf '%sSKIP:%s %s\n' "$(color yellow)" "$(color reset)" "$*" >&2
  exit 0
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    skip "$cmd not found"
  fi
}

color_enabled() {
  if [ -n "${NO_COLOR:-}" ]; then
    return 1
  fi
  if [ "${TERM:-dumb}" = "dumb" ]; then
    return 1
  fi
  [ -t 2 ]
}

color() {
  local name="$1"
  if ! color_enabled; then
    return 0
  fi
  case "$name" in
    red) printf '\033[31m' ;;
    green) printf '\033[32m' ;;
    yellow) printf '\033[33m' ;;
    blue) printf '\033[34m' ;;
    magenta) printf '\033[35m' ;;
    cyan) printf '\033[36m' ;;
    reset) printf '\033[0m' ;;
  esac
}

info() {
  printf '%sINFO:%s %s\n' "$(color cyan)" "$(color reset)" "$*" >&2
}

pass() {
  printf '%sPASS:%s %s\n' "$(color green)" "$(color reset)" "$*" >&2
}
