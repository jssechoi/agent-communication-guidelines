#!/usr/bin/env bash
# Installs the agent-communication-guidelines tone standard for Claude Code,
# Gemini CLI and Codex on macOS and Linux. The Windows equivalent is install.ps1.
#
# Every edit is wrapped in HTML comment markers and replaced in place on a
# re-run, so running this repeatedly is safe. Existing files are backed up
# before the first change.
#
# Usage:
#   install/install.sh                        # all three tools
#   install/install.sh --tools gemini,codex   # a subset
#   install/install.sh --dry-run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SNIPPET_DIR="$SCRIPT_DIR/snippets"
RULES_PATH="$REPO_ROOT/skills/agent-tone/SKILL.md"
BEGIN_TAG='<!-- agent-communication-guidelines:begin -->'
END_TAG='<!-- agent-communication-guidelines:end -->'

TOOLS="all"
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --tools) TOOLS="$2"; shift 2 ;;
    --tools=*) TOOLS="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

[ -f "$RULES_PATH" ] || { echo "Run this from inside the cloned repository. Not found: $RULES_PATH" >&2; exit 1; }

case ",$TOOLS," in *,all,*) TOOLS="claude,gemini,codex" ;; esac
for t in ${TOOLS//,/ }; do
  case "$t" in
    claude|gemini|codex) ;;
    *) echo "Unknown tool: $t. Use all, or a comma-separated list of: claude, gemini, codex" >&2; exit 2 ;;
  esac
done
has_tool() { case ",$TOOLS," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

changed=0
skipped=0

build_block() {
  # $1 = head snippet file name
  printf '%s\n' "$BEGIN_TAG"
  sed "s|{{GUIDELINES_PATH}}|$RULES_PATH|g" "$SNIPPET_DIR/$1" | tr -d '\r' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
  printf '\n'
  tr -d '\r' < "$SNIPPET_DIR/mandate-core.md" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
  printf '%s\n' "$END_TAG"
}

set_mandate() {
  # $1 = target path, $2 = head snippet, $3 = label
  local path="$1" head="$2" label="$3" tmp new_content action
  tmp="$(mktemp)"
  if [ -f "$path" ]; then
    if grep -qF "$BEGIN_TAG" "$path"; then
      action="update"
      awk -v b="$BEGIN_TAG" -v e="$END_TAG" '
        index($0, b) { skip = 1 }
        skip == 0 { print }
        index($0, e) { skip = 0 }
      ' "$path" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$tmp"
      # Only separate from preceding text. A file whose whole content was the
      # block must come back byte-identical on a re-run.
      if [ -s "$tmp" ]; then printf '\n' >> "$tmp"; fi
    else
      action="append"
      sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$path" > "$tmp"
      # Only separate from preceding text. A file whose whole content was the
      # block must come back byte-identical on a re-run.
      if [ -s "$tmp" ]; then printf '\n' >> "$tmp"; fi
    fi
  else
    action="create"
    : > "$tmp"
  fi
  build_block "$head" >> "$tmp"

  if [ -f "$path" ] && cmp -s "$tmp" "$path"; then
    echo "  [same]   $label"
    skipped=$((skipped + 1))
    rm -f "$tmp"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [$action] $label -> $path"
    rm -f "$tmp"
    return
  fi
  mkdir -p "$(dirname "$path")"
  if [ -f "$path" ]; then
    local backup="$path.bak-$(date +%Y%m%d-%H%M%S)"
    cp "$path" "$backup"
    echo "  [backup] $backup"
  fi
  mv "$tmp" "$path"
  echo "  [$action] $label"
  changed=$((changed + 1))
}

echo
echo "agent-communication-guidelines installer"
echo "  repository : $REPO_ROOT"
echo "  tools      : $TOOLS"
[ "$DRY_RUN" -eq 1 ] && echo "  mode       : dry run, nothing is written"
echo

if has_tool claude; then
  echo "Claude Code"
  skill_dir="$HOME/.claude/skills/agent-communication-guidelines"
  if [ "$REPO_ROOT" = "$skill_dir" ]; then
    echo "  [same]   repository is already the skills-dir plugin"
  elif [ "$DRY_RUN" -eq 1 ]; then
    echo "  [copy]   $REPO_ROOT -> $skill_dir"
  else
    mkdir -p "$skill_dir"
    (cd "$REPO_ROOT" && tar --exclude=./.git -cf - .) | (cd "$skill_dir" && tar -xf -)
    echo "  [copy]   $skill_dir"
    changed=$((changed + 1))
  fi
  set_mandate "$HOME/.claude/CLAUDE.md" head-claude.md "CLAUDE.md mandate"
  echo
fi

if has_tool gemini; then
  echo "Gemini CLI"
  g_skill="$HOME/.gemini/skills/agent-communication-guidelines"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [write]  $g_skill/SKILL.md"
    echo "  [write]  $g_skill/references/guidelines.md"
  else
    mkdir -p "$g_skill/references"
    tr -d '\r' < "$SCRIPT_DIR/gemini-skill/SKILL.md" \
      | sed -e "/{{MANDATE}}/r $SNIPPET_DIR/mandate-core.md" -e "/{{MANDATE}}/d" \
      | tr -d '\r' > "$g_skill/SKILL.md"
    cp "$RULES_PATH" "$g_skill/references/guidelines.md"
    echo "  [write]  $g_skill"
    changed=$((changed + 1))
  fi
  set_mandate "$HOME/.gemini/GEMINI.md" head-gemini.md "GEMINI.md mandate"
  echo
fi

if has_tool codex; then
  echo "Codex"
  set_mandate "$HOME/.codex/AGENTS.md" head-codex.md "AGENTS.md mandate"
  echo
fi

echo "Done. $changed written, $skipped already current."
[ "$DRY_RUN" -eq 1 ] || echo "Rules load on each tool's next session."
