#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
	cat <<'EOF'
Usage: ./run-tests.sh [options]

Options:
	-h, --help     Show this help
	--no-color     Disable colored output
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		-h|--help)
			usage
			exit 0
			;;
		--no-color)
			export NO_COLOR=1
			shift
			;;
		*)
			break
			;;
	esac
done

"$ROOT_DIR/build.sh" >/dev/null

export ROOT_DIR
export APP="$ROOT_DIR/bin/bumbuhelper"
export TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

. "$ROOT_DIR/tests/lib.sh"

mapfile -t test_files < <(find "$ROOT_DIR/tests" -type f -name 'test-*.sh' | sort)

if [ "${#test_files[@]}" -eq 0 ]; then
	fail "No tests found"
fi

for test_file in "${test_files[@]}"; do
	info "Running ${test_file#$ROOT_DIR/}"
	bash "$test_file"
	pass "${test_file#$ROOT_DIR/}"
done

pass "All tests passed"
