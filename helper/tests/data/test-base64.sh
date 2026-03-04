#!/usr/bin/env bash
set -euo pipefail

. "$ROOT_DIR/tests/lib.sh"

require_cmd base64

input="hello world"
encoded="$(printf '%s' "$input" | run_cmd data base64)"
decoded="$(printf '%s' "$encoded" | run_cmd data base64 --decode)"

assert_eq "$input" "$decoded" "base64 roundtrip"

auto_decoded="$(printf '%s' "$encoded" | run_cmd data base64)"
assert_eq "$input" "$auto_decoded" "base64 auto decode"
