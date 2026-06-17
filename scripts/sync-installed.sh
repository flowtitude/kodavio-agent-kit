#!/usr/bin/env bash
#
# Sync the kit SOURCE (this repo) into an INSTALLED copy, without touching the
# installed copy's personal/local layer. Run this after updating the source so the
# installed kit (e.g. sa-workspace/wp-agents) picks up new skills/agents/docs while
# your machine-specific config, secrets and sites stay put.
#
# Usage:  scripts/sync-installed.sh [TARGET_DIR]
#         (default TARGET_DIR: <workspace-root>/wp-agents)
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_TARGET="$(cd "$SOURCE_DIR/../.." 2>/dev/null && pwd)/wp-agents"
TARGET_DIR="${1:-$DEFAULT_TARGET}"

if [[ -L "$TARGET_DIR" ]]; then
  echo "[sync] ERROR: $TARGET_DIR is a symlink. The installed copy must be a real directory, decoupled from the source." >&2
  echo "[sync] Remove the symlink and run this script to create a real installed copy." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

# Personal/local layer — lives ONLY in the installed copy; never overwritten or deleted.
EXCLUDES=(
  --exclude='.git/'
  --exclude='.komandesk/'
  --exclude='sites/'
  --exclude='registry/sites.json'
  --exclude='state.md'
  --exclude='.claude/settings.local.json'
  --exclude='.cursor/mcp.json'
  --exclude='kilo.jsonc'
  --exclude='.kilo/'
  --exclude='*.local'
  --exclude='*.local.*'
  --exclude='secrets.local.env'
)

rsync -a --delete "${EXCLUDES[@]}" "$SOURCE_DIR"/ "$TARGET_DIR"/

echo "[sync] Source -> installed copy synced."
echo "[sync]   source:    $SOURCE_DIR"
echo "[sync]   installed: $TARGET_DIR"
echo "[sync] Your personal layer (.komandesk, sites, *.local, secrets, state.md) was preserved."
