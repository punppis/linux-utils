#!/usr/bin/env bash
set -euo pipefail

. "$ROOT_DIR/tests/lib.sh"

require_cmd openssl

input="hello world"
expected="$(printf '%s' "$input" | openssl dgst -sha256 | awk '{print $NF}')"
actual="$(printf '%s' "$input" | run_cmd transform hash)"

assert_eq "$expected" "$actual" "hash sha256"
