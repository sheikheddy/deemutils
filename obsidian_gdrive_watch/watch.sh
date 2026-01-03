#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH
VAULT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"
EXPORT_SCRIPT="$SCRIPT_DIR/export_and_upload.sh"
LOG_FILE="$SCRIPT_DIR/watch.log"
LOCK_FILE="$SCRIPT_DIR/.export.lock"

if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

SOURCE_MD="${SOURCE_MD:-$VAULT_DIR/Character Counting Computation Happens via Attention.md}"
POLL_SECONDS="${POLL_SECONDS:-5}"

if [ ! -x "$EXPORT_SCRIPT" ]; then
  echo "Export script not executable: $EXPORT_SCRIPT" >&2
  exit 1
fi

last_mtime="0"

while true; do
  if [ -f "$SOURCE_MD" ]; then
    mtime="$(stat -f "%m" "$SOURCE_MD")"
    if [ "$mtime" != "$last_mtime" ]; then
      last_mtime="$mtime"
      if ( set -o noclobber; echo "$$" > "$LOCK_FILE" ) 2>/dev/null; then
        {
          echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") change detected"
          "$EXPORT_SCRIPT"
          echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") export complete"
        } >> "$LOG_FILE" 2>&1
        rm -f "$LOCK_FILE"
      else
        echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") export skipped (lock present)" >> "$LOG_FILE"
      fi
    fi
  fi
  sleep "$POLL_SECONDS"
done
