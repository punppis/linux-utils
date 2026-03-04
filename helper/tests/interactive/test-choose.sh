#!/usr/bin/env bash
set -euo pipefail

. "$ROOT_DIR/tests/lib.sh"

out="$(printf 'a\nb\n' | run_cmd interactive choose --default b)"
assert_eq "b" "$out" "choose default in non-tty"
