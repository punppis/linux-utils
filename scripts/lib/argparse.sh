#!/usr/bin/env bash
# shellcheck shell=bash

# Lightweight, reusable argument parsing helpers.
# Supports: short (-s) and long (--silent) flags, value options with space or '=' delimiter,
# preserved positional args, and '--' terminator.
# Does not support clustered short flags (e.g., -abc); keep one flag/option per token.
#
# Example usage in a script:
#   source "$(dirname "$0")/lib/argparse.sh"
#   argparse_init "myscript"
#   argparse_add_flag   "-s" "--silent"    SILENT    "Silence output"
#   argparse_add_flag   "-y" "--yes"       ASSUME_YES "Assume yes to prompts"
#   argparse_add_option "-p" "--packages"  PACKAGES  "Extra packages (space-separated)" "jq htop"
#   argparse_add_option "-u" "--user"      TARGET_USER "Target username" ""
#   argparse_parse "$@"
#   # Use parsed values: $SILENT, $ASSUME_YES, $PACKAGES, $TARGET_USER
#   # Positional args are in ${ARGPARSE_POSITIONAL[@]}

argparse_init() {
  ARGPARSE_SCRIPT_NAME="${1:-$(basename "$0" 2>/dev/null || echo script)}"
  ARGPARSE_FLAGS=()
  ARGPARSE_OPTIONS=()
  ARGPARSE_POSITIONAL=()
}

argparse_add_flag() {
  local short="$1" long="$2" var="$3" help="${4:-}"
  eval "${var}=false"
  ARGPARSE_FLAGS+=("${short}|${long}|${var}|${help}")
}

argparse_add_option() {
  local short="$1" long="$2" var="$3" help="${4:-}" default="${5-}"
  eval "${var}=\"${default}\""
  ARGPARSE_OPTIONS+=("${short}|${long}|${var}|${help}|${default}")
}

argparse_print_help() {
  echo "Usage: ${ARGPARSE_SCRIPT_NAME} [options] [--] [args...]"
  echo
  echo "Options:"
  local entry short long var help default
  for entry in "${ARGPARSE_FLAGS[@]}"; do
    IFS='|' read -r short long var help <<<"$entry"
    printf "  %-4s %-15s %s\n" "$short" "$long" "$help"
  done
  for entry in "${ARGPARSE_OPTIONS[@]}"; do
    IFS='|' read -r short long var help default <<<"$entry"
    printf "  %-4s %-15s %s" "$short" "$long" "$help"
    if [[ -n "$default" ]]; then
      printf " (default: %s)" "$default"
    fi
    printf "\n"
  done
}

argparse_fail() {
  local message="$1"
  echo "Error: $message" >&2
  echo >&2
  argparse_print_help >&2
  exit 1
}

argparse_lookup() {
  local token="$1" entry short long var help default
  for entry in "${ARGPARSE_FLAGS[@]}"; do
    IFS='|' read -r short long var help <<<"$entry"
    if [[ "$token" == "$short" || "$token" == "$long" ]]; then
      ARGPARSE_MATCH_TYPE="flag"
      ARGPARSE_MATCH_ENTRY="$entry"
      return 0
    fi
  done
  for entry in "${ARGPARSE_OPTIONS[@]}"; do
    IFS='|' read -r short long var help default <<<"$entry"
    if [[ "$token" == "$short" || "$token" == "$long" ]]; then
      ARGPARSE_MATCH_TYPE="option"
      ARGPARSE_MATCH_ENTRY="$entry"
      return 0
    fi
  done
  return 1
}

argparse_set_flag() {
  IFS='|' read -r _ _ var _ <<<"$1"
  eval "${var}=true"
}

argparse_set_option() {
  local entry="$1" value="$2"
  IFS='|' read -r _ _ var _ _ <<<"$entry"
  eval "${var}=\"${value}\""
}

argparse_parse() {
  local token value entry
  while [[ $# -gt 0 ]]; do
    token="$1"
    case "$token" in
      --)
        shift
        ARGPARSE_POSITIONAL+=("$@")
        break
        ;;
      --*=*)
        local key="${token%%=*}"
        value="${token#*=}"
        if ! argparse_lookup "$key"; then
          argparse_fail "Unknown option: $key"
        fi
        if [[ "$ARGPARSE_MATCH_TYPE" == "flag" ]]; then
          argparse_fail "Flag '$key' does not take a value"
        fi
        argparse_set_option "$ARGPARSE_MATCH_ENTRY" "$value"
        shift
        ;;
      --*)
        if ! argparse_lookup "$token"; then
          argparse_fail "Unknown option: $token"
        fi
        if [[ "$ARGPARSE_MATCH_TYPE" == "flag" ]]; then
          argparse_set_flag "$ARGPARSE_MATCH_ENTRY"
          shift
        else
          if [[ $# -lt 2 ]]; then
            argparse_fail "Option '$token' requires a value"
          fi
          argparse_set_option "$ARGPARSE_MATCH_ENTRY" "$2"
          shift 2
        fi
        ;;
      -*)
        if ! argparse_lookup "$token"; then
          argparse_fail "Unknown option: $token"
        fi
        if [[ "$ARGPARSE_MATCH_TYPE" == "flag" ]]; then
          argparse_set_flag "$ARGPARSE_MATCH_ENTRY"
          shift
        else
          if [[ "$token" == *=* ]]; then
            value="${token#*=}"
            argparse_set_option "$ARGPARSE_MATCH_ENTRY" "$value"
            shift
          else
            if [[ $# -lt 2 ]]; then
              argparse_fail "Option '$token' requires a value"
            fi
            argparse_set_option "$ARGPARSE_MATCH_ENTRY" "$2"
            shift 2
          fi
        fi
        ;;
      *)
        ARGPARSE_POSITIONAL+=("$token")
        shift
        ;;
    esac
  done
}
