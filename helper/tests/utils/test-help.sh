#!/usr/bin/env bash
set -euo pipefail

. "$ROOT_DIR/tests/lib.sh"

help_out="$(run_cmd help)"
case "$help_out" in
  *"Groups:"*) : ;;
  *) fail "help output missing Groups section" ;;
esac
