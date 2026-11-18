#!/bin/sh
# Installs the failedci2claude Stop hook for Claude Code: copies the script to ~/.claude/hooks and registers it in
# ~/.claude/settings.json. Safe to run twice. Needs python3 and an authenticated `gh`.
set -eu

DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
RAW="${FAILEDCI_RAW:-https://raw.githubusercontent.com/flisk-sh/failedci2claude/main/hook/failedci2claude.py}"

mkdir -p "$DIR"
SRC="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/hook/failedci2claude.py"
if [ -f "$SRC" ]; then
  cp "$SRC" "$DIR/failedci2claude.py"
else
  curl -fsSL "$RAW" -o "$DIR/failedci2claude.py"
fi
chmod +x "$DIR/failedci2claude.py"

python3 - "$SETTINGS" <<'PY'
import json, os, shutil, sys
path = sys.argv[1]
cmd = 'python3 "$HOME/.claude/hooks/failedci2claude.py"'
try:
    data = json.load(open(path))
except FileNotFoundError:
    data = {}
stop = data.setdefault("hooks", {}).setdefault("Stop", [])
if any("failedci2claude.py" in h.get("command", "") for g in stop for h in g.get("hooks", [])):
    print("already registered")
else:
    if os.path.exists(path):
        shutil.copy(path, path + ".bak")
    stop.append({"hooks": [{"type": "command", "command": cmd, "timeout": 30}]})
    os.makedirs(os.path.dirname(path), exist_ok=True)
    json.dump(data, open(path, "w"), indent=2)
    print("registered in " + path)
PY

command -v gh >/dev/null 2>&1 || echo "note: gh not found on PATH; install it and run 'gh auth login'" >&2
echo "failedci2claude installed. Start a new Claude Code session: hooks load at session start."
