#!/usr/bin/env bash
set -euo pipefail

. "$ROOT_DIR/tests/lib.sh"

script_path="$(run_cmd fs path get_current_script)"
[ -f "$script_path" ] || fail "get_current_script returned non-file path"

script_dir="$(printf '%s\n' "$script_path" | run_cmd fs path get_path)"
[ -d "$script_dir" ] || fail "get_path returned non-dir path"

tmp_file="$script_dir/.helper_test_input.csv"
tmp_out="$TMP_DIR/output.txt"

printf 'a,b,c\n1,2,3\n' > "$tmp_file"
line_count="$(wc -l < "$tmp_file" | tr -d '[:space:]')"
assert_int "$line_count" "line_count is integer"

run_cmd utils create_array --separators "," < "$tmp_file" > "$tmp_out"
out_size="$(wc -c < "$tmp_out" | tr -d '[:space:]')"
assert_int "$out_size" "output size is integer"

rm -f "$tmp_file"
