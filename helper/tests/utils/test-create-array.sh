#!/usr/bin/env bash
set -euo pipefail

. "$ROOT_DIR/tests/lib.sh"

create_out="$(printf 'a\nb\n' | run_cmd utils create_array)"
assert_eq "(a b )" "$create_out" "create_array stdin"

create_csv_out="$(printf 'a,b' | run_cmd utils create_array --separators ',')"
assert_eq "(a b )" "$create_csv_out" "create_array separators"

create_alias_out="$(printf 'x\ny' | run_cmd helper create_array)"
assert_eq "(x y )" "$create_alias_out" "alias prefix helper"
