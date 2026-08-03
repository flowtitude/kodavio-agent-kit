#!/usr/bin/env bash
#
# Generate .codex/agents/*.toml from agents/*.md — SINGLE SOURCE: agents/*.md
#
# Codex needs its subagents as TOML (name / description / developer_instructions);
# Claude Code and Kilo read the markdown directly. Keeping both by hand guarantees
# drift, so the TOML is GENERATED and committed. Never edit .codex/agents/ by hand.
#
# Usage:  scripts/gen-codex-agents.sh [--check]
#           (no args)  regenerate the TOML files
#           --check    exit 1 if any TOML is missing or stale (used by doctor.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT/agents"
OUT_DIR="$ROOT/.codex/agents"
CHECK_ONLY=0
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=1

# Read a frontmatter field from a markdown file (first match, value verbatim).
fm_field() {
  awk -v key="$2" '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---"   { exit }
    inside && index($0, key ": ") == 1 { print substr($0, length(key) + 3); exit }
  ' "$1"
}

# Body = everything after the closing --- of the frontmatter, trimmed.
fm_body() {
  awk '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---"   { inside = 0; started = 1; next }
    started { print }
  ' "$1" | sed -e '/./,$!d' | awk '{ lines[NR] = $0 } END { last = NR; while (last > 0 && lines[last] == "") last--; for (i = 1; i <= last; i++) print lines[i] }'
}

render_toml() {
  local md="$1" name description body
  name="$(fm_field "$md" name)"
  description="$(fm_field "$md" description)"
  body="$(fm_body "$md")"

  if [[ -z "$name" || -z "$description" || -z "$body" ]]; then
    echo "[gen-codex] ERROR: $md has no name, description or body in its frontmatter." >&2
    return 1
  fi
  # TOML basic strings escape backslashes and double quotes; the body goes into a
  # multi-line literal-ish string, so only """ sequences would break it.
  if [[ "$body" == *'"""'* ]]; then
    echo "[gen-codex] ERROR: $md body contains \"\"\", which breaks the TOML block string." >&2
    return 1
  fi

  printf 'name = "%s"\n' "${name//\"/\\\"}"
  printf 'description = "%s"\n' "${description//\"/\\\"}"
  printf 'developer_instructions = """\n%s"""\n' "$body"
}

mkdir -p "$OUT_DIR"
stale=0
generated=0

for md in "$SRC_DIR"/*.md; do
  slug="$(basename "$md" .md)"
  out="$OUT_DIR/$slug.toml"
  tmp="$(mktemp)"
  render_toml "$md" > "$tmp"

  if [[ $CHECK_ONLY -eq 1 ]]; then
    if [[ ! -f "$out" ]] || ! cmp -s "$tmp" "$out"; then
      echo "[gen-codex] STALE: $out (regenerate with scripts/gen-codex-agents.sh)" >&2
      stale=1
    fi
    rm -f "$tmp"
  else
    mv "$tmp" "$out"
    generated=$((generated + 1))
  fi
done

# TOML files whose markdown source disappeared.
for toml in "$OUT_DIR"/*.toml; do
  [[ -e "$toml" ]] || continue
  slug="$(basename "$toml" .toml)"
  if [[ ! -f "$SRC_DIR/$slug.md" ]]; then
    if [[ $CHECK_ONLY -eq 1 ]]; then
      echo "[gen-codex] ORPHAN: $toml has no agents/$slug.md" >&2
      stale=1
    else
      rm -f "$toml"
      echo "[gen-codex] removed orphan $toml"
    fi
  fi
done

if [[ $CHECK_ONLY -eq 1 ]]; then
  [[ $stale -eq 0 ]] && echo "[gen-codex] .codex/agents is in sync with agents/."
  exit $stale
fi

echo "[gen-codex] generated $generated agent(s) into $OUT_DIR"
