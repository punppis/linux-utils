#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
OUT_DIR="$ROOT_DIR/bin"
OUT_FILE="$OUT_DIR/bumbuhelper"

mkdir -p "$OUT_DIR"

{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  echo ''
  for dir in utils interactive fs ssh docker data compress transform; do
    if [ -d "$SRC_DIR/functions/$dir" ]; then
      while IFS= read -r f; do
        echo "# --- $f ---"
        cat "$f"
        echo ''
      done < <(find "$SRC_DIR/functions/$dir" -type f -name '*.sh' | sort)
    fi
  done
  echo "# --- $SRC_DIR/app.sh ---"
  cat "$SRC_DIR/app.sh"
  echo ''
} > "$OUT_FILE"

chmod +x "$OUT_FILE"

if [ $# -gt 0 ]; then
  "$OUT_FILE" install
  printf 'Running: %s %s\n' "$OUT_FILE" "$*"
  "$OUT_FILE" "$@"
elif [[ -t 0 ]]; then
  printf 'Built: %s\n' "$OUT_FILE"
fi

if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
  source <("$OUT_FILE" autocomplete) >/dev/null 2>&1 || true
fi