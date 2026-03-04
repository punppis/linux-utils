#!/usr/bin/env bash
set -euo pipefail

. "$ROOT_DIR/tests/lib.sh"

require_cmd openssl

work_dir="$TMP_DIR/crypto"
mkdir -p "$work_dir"

input_file="$work_dir/input.txt"
enc_file="$work_dir/input.txt.enc"
dec_file="$work_dir/input.txt.dec"

printf 'secret line\n' > "$input_file"

run_cmd transform encrypt "$input_file" --password "testpass" --output "$enc_file"
[ -f "$enc_file" ] || fail "encrypted file missing"

run_cmd transform decrypt "$enc_file" --password "testpass" --output "$dec_file"
[ -f "$dec_file" ] || fail "decrypted file missing"

assert_eq "$(cat "$input_file")" "$(cat "$dec_file")" "encrypt/decrypt roundtrip"
