#!/bin/bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: obsidian_gdrive_sync.sh [--push|--pull] [--dry-run]

Defaults:
  VAULT_PATH   $HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents
  GDRIVE_REMOTE  gdrive:Obsidian

Options:
  --push     Sync local vault to Google Drive (default)
  --pull     Sync Google Drive to local vault
  --dry-run  Show what would change without applying
  -h, --help Show this help

Notes:
  - Requires rclone and a configured Google Drive remote.
  - Run `rclone config` and name the remote to match GDRIVE_REMOTE.
USAGE
}

DEFAULT_VAULT_PATH="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"
VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT_PATH}"
GDRIVE_REMOTE="${GDRIVE_REMOTE:-gdrive:Obsidian}"
MODE="push"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push)
      MODE="push"
      ;;
    --pull)
      MODE="pull"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ! command -v rclone >/dev/null 2>&1; then
  echo "rclone is required. Install with: brew install rclone" >&2
  exit 1
fi

if [[ ! -d "$VAULT_PATH" ]]; then
  echo "Vault path not found: $VAULT_PATH" >&2
  exit 1
fi

EXCLUDE_ARGS=(
  "--exclude" ".DS_Store"
  "--exclude" ".obsidian/cache/**"
  "--exclude" ".obsidian/workspace"
  "--exclude" ".obsidian/workspace-mobile"
)

RCLONE_ARGS=(
  "--fast-list"
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  RCLONE_ARGS+=("--dry-run")
fi

if [[ "$MODE" == "push" ]]; then
  SRC="$VAULT_PATH"
  DST="$GDRIVE_REMOTE"
else
  SRC="$GDRIVE_REMOTE"
  DST="$VAULT_PATH"
fi

rclone sync "$SRC" "$DST" "${EXCLUDE_ARGS[@]}" "${RCLONE_ARGS[@]}"
