#!/usr/bin/env bash
set -euo pipefail

. "$ROOT_DIR/tests/lib.sh"

require_cmd tar

work_dir="$TMP_DIR/compress"
mkdir -p "$work_dir/src"

printf 'hello world\n' > "$work_dir/src/hello.txt"

archive="$work_dir/data.tar.gz"
run_cmd compress compress "$work_dir/src" --output "$archive"
[ -f "$archive" ] || fail "archive not created"

out_dir="$work_dir/out"
run_cmd compress decompress "$archive" --output "$out_dir"

[ -f "$out_dir/src/hello.txt" ] || fail "decompressed file missing"
assert_eq "hello world" "$(cat "$out_dir/src/hello.txt")" "decompressed content"
