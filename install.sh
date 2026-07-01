#!/usr/bin/env bash
# install.sh — lay the factory out into ~/.claude with the correct structure.
# Run from the unpacked factory bundle directory. Idempotent-ish: it won't clobber an existing
# CLAUDE.md or settings.json without asking, since those may already hold your edits.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"

echo "Installing factory into $DEST"
mkdir -p "$DEST"/{skills,hooks,commands,shapes,workflows}
mkdir -p "$DEST"/skills/{new-line,spec-interview,eval-scaffold,add-stack-part,as-built,import-handoff,foreman}
mkdir -p "$DEST"/commands
mkdir -p "$DEST"/shapes/{docker-analog/analog,aws-dev-analog/analog}

copy() { # copy SRC_REL DEST_REL
  local s="$SRC/$1" d="$DEST/$2"
  mkdir -p "$(dirname "$d")"
  cp "$s" "$d"
  echo "  $2"
}

backup_copy() { # back up a preexisting destination file, then overwrite
  local s="$SRC/$1" d="$DEST/$2"
  mkdir -p "$(dirname "$d")"
  if [ -e "$d" ]; then
    local bak="$d.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$d" "$bak"
    echo "  BACKED UP existing $2 -> $(basename "$bak")"
  fi
  cp "$s" "$d"; echo "  $2"
}

install_settings() { # the factory OWNS only hooks + routing; preserve any other keys on re-install
  local s="$SRC/settings.json" d="$DEST/settings.json" hooks_dir="$DEST/hooks"
  local tmp; tmp="$(mktemp)"
  # Rewrite machine-specific tokens: POSIX interpreter + absolute hooks dir.
  sed -e "s|__PYTHON__|python3|g" -e "s|__HOOKS_DIR__|$hooks_dir|g" "$s" > "$tmp"
  if [ -e "$d" ]; then
    local bak="$d.bak.$(date +%Y%m%d-%H%M%S)"; cp "$d" "$bak"
    echo "  BACKED UP existing settings.json -> $(basename "$bak")"
    if command -v jq >/dev/null 2>&1; then
      # Deep-merge: existing first, factory second (factory wins on hooks/routing; arrays replaced).
      jq -s '.[0] * .[1]' "$bak" "$tmp" > "$d"
      echo "  settings.json (hooks + routing merged via jq; other keys preserved)"
    else
      cp "$tmp" "$DEST/settings.factory.json"
      echo "  jq not found — existing settings.json left UNTOUCHED."
      echo "  Wrote the factory block to settings.factory.json; merge its 'hooks' and 'routing' keys in by hand."
    fi
  else
    cp "$tmp" "$d"; echo "  settings.json"
  fi
  rm -f "$tmp"
}

echo "core:"
backup_copy "CLAUDE.md" "CLAUDE.md"
install_settings
# stack.md accretes your real tech standard over time — never clobber a populated one.
# Install the empty template only if absent.
if [ -e "$DEST/stack.md" ]; then
  echo "  KEPT existing stack.md (accreted standard — not overwritten)"
else
  cp "$SRC/stack.md" "$DEST/stack.md"; echo "  stack.md"
fi

echo "skills:"
copy "new-line-SKILL.md"       "skills/new-line/SKILL.md"
copy "spec-interview-SKILL.md" "skills/spec-interview/SKILL.md"
copy "eval-scaffold-SKILL.md"  "skills/eval-scaffold/SKILL.md"
copy "add-stack-part-SKILL.md" "skills/add-stack-part/SKILL.md"
copy "as-built-SKILL.md"       "skills/as-built/SKILL.md"
copy "import-handoff-SKILL.md" "skills/import-handoff/SKILL.md"
copy "foreman-SKILL.md"        "skills/foreman/SKILL.md"
copy "program-scaffold-REFERENCE.md" "skills/foreman/program-scaffold-REFERENCE.md"

echo "commands:"
copy "retro-COMMAND.md"   "commands/retro.md"
copy "promote-COMMAND.md" "commands/promote.md"
copy "submit-COMMAND.md"  "commands/submit.md"
copy "program-COMMAND.md" "commands/program.md"

echo "hooks:"
copy "burn-detect.py" "hooks/burn-detect.py"
copy "cost-log.py"    "hooks/cost-log.py"
copy "cred-guard.py"  "hooks/cred-guard.py"
copy "loop-gate.py"   "hooks/loop-gate.py"
chmod +x "$DEST"/hooks/*.py

echo "shapes/docker-analog:"
copy "shapes/docker-analog/README.md"             "shapes/docker-analog/README.md"
copy "shapes/docker-analog/docker-compose.yml"    "shapes/docker-analog/docker-compose.yml"
copy "shapes/docker-analog/analog/apply.sh"       "shapes/docker-analog/analog/apply.sh"
copy "shapes/docker-analog/analog/teardown.sh"    "shapes/docker-analog/analog/teardown.sh"
chmod +x "$DEST"/shapes/docker-analog/analog/*.sh

echo "shapes/aws-dev-analog:"
copy "shapes/aws-dev-analog/README.md"            "shapes/aws-dev-analog/README.md"
copy "shapes/aws-dev-analog/analog/bootstrap.sh"  "shapes/aws-dev-analog/analog/bootstrap.sh"
copy "shapes/aws-dev-analog/analog/teardown.sh"   "shapes/aws-dev-analog/analog/teardown.sh"
chmod +x "$DEST"/shapes/aws-dev-analog/analog/*.sh

echo "workflows:"
copy "workflows/deploy.yml" "workflows/deploy.yml"

touch "$DEST/factory-log.jsonl"

echo
echo "Factory installed. ~/prototypes/ is the floor; spin a line with /new-line."
echo "Hooks are wired with python3 + absolute paths and merged into your settings.json (other keys kept)."
echo "Note: the settings.json 'routing' block is a documentation placeholder (not read by Claude Code)."
echo "Wire your IaC scanner into workflows/deploy.yml."
