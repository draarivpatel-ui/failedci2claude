"""The repository dogfoods itself: opening it in Claude Code loads the skill and the Stop hook."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_the_skill_is_reachable_from_claude_and_other_agents():
    for base in (".claude/skills", ".agents/skills"):
        skill = ROOT / base / "backtogreen" / "SKILL.md"
        assert skill.is_file(), f"{base}/backtogreen does not resolve to a skill"
        assert skill.read_text().startswith("---\nname: backtogreen\n")


def test_the_project_settings_register_the_real_stop_hook():
    cfg = json.loads((ROOT / ".claude" / "settings.json").read_text())
    cmd = cfg["hooks"]["Stop"][0]["hooks"][0]["command"]
    assert "$CLAUDE_PROJECT_DIR/.claude/hooks/failedci2claude.py" in cmd
    assert (ROOT / ".claude" / "hooks" / "failedci2claude.py").is_file()
    assert (ROOT / ".claude" / "hooks" / "failedci2claude.py").resolve() == (ROOT / "hook" / "failedci2claude.py").resolve()


def test_the_registered_command_runs_and_stays_quiet_with_nothing_to_report(tmp_path):
    cfg = json.loads((ROOT / ".claude" / "settings.json").read_text())
    cmd = cfg["hooks"]["Stop"][0]["hooks"][0]["command"].replace("python3", sys.executable, 1)
    proc = subprocess.run(
        cmd, shell=True, input="{}", capture_output=True, text=True, cwd=ROOT,
        env={"HOME": str(tmp_path), "PATH": "/usr/bin:/bin", "CLAUDE_PROJECT_DIR": str(ROOT)},
    )
    assert proc.returncode == 0, proc.stderr
