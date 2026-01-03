#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH
VAULT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

SOURCE_MD="${SOURCE_MD:-$VAULT_DIR/Character Counting Computation Happens via Attention.md}"
OUTPUT_DOCX="${OUTPUT_DOCX:-$VAULT_DIR/Character Counting Computation Happens via Attention.docx}"
CHARCOUNT_FILE="${CHARCOUNT_FILE:-$VAULT_DIR/Character Counting Computation Happens via Attention.charcount.txt}"
FILE_ID_CACHE="${FILE_ID_CACHE:-$SCRIPT_DIR/drive_file_id.txt}"
RCLONE_REMOTE="${RCLONE_REMOTE:-gdrive:}"
RCLONE_TARGET_DIR="${RCLONE_TARGET_DIR:-ObsidianExports}"

if [ ! -f "$SOURCE_MD" ]; then
  echo "Source markdown not found: $SOURCE_MD" >&2
  exit 1
fi

CHAR_COUNT="$(python3 - <<'PY' "$SOURCE_MD"
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
print(len(text))
PY
)"

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
printf "%s\t%s\t%s\n" "$TS" "$CHAR_COUNT" "$SOURCE_MD" >> "$CHARCOUNT_FILE"

pandoc \
  --from=markdown+wikilinks_title_after_pipe+wikilinks_title_before_pipe \
  --resource-path="$VAULT_DIR" \
  "$SOURCE_MD" \
  -o "$OUTPUT_DOCX"

REMOTE_DIR="$RCLONE_REMOTE$RCLONE_TARGET_DIR"
REMOTE_PATH="$REMOTE_DIR/$(basename "$OUTPUT_DOCX")"

rclone mkdir "$REMOTE_DIR" >/dev/null 2>&1 || true
rclone copyto "$OUTPUT_DOCX" "$REMOTE_PATH"

LSJSON="$(rclone lsjson "$REMOTE_PATH" 2>/dev/null || true)"
REMOTE_ID=""
if [ -n "$LSJSON" ]; then
  REMOTE_ID="$(printf "%s" "$LSJSON" | python3 -c 'import json,sys; items=json.load(sys.stdin); print(items[0].get("ID","") if items else "")')"
fi

if [ -n "$REMOTE_ID" ]; then
  if [ -f "$FILE_ID_CACHE" ]; then
    PREV_ID="$(cat "$FILE_ID_CACHE")"
    if [ -n "$PREV_ID" ] && [ "$PREV_ID" != "$REMOTE_ID" ]; then
      echo "Warning: Drive file ID changed: $PREV_ID -> $REMOTE_ID" >&2
    fi
  fi
  printf "%s\n" "$REMOTE_ID" > "$FILE_ID_CACHE"
fi
