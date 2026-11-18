# failedci2claude

A Claude Code **Stop hook** that tells your session when CI failed on one of your open pull requests, so the session
that opened the PR is the one that fixes it.

## Install

```sh
git clone https://github.com/flisk-sh/failedci2claude && cd failedci2claude && ./install.sh
```

Needs `python3` and the GitHub CLI (`gh auth login`). Hooks load when a session starts, so open a **new** Claude Code
session afterwards.

## How it works

When a turn ends, the hook:

1. lists the branches checked out in the repo's worktrees (a session often opens its PRs from other worktrees);
2. makes **one** `gh pr list --author @me` call and matches those branches to your open PRs;
3. if any check failed, answers Claude with the failing check names, so it finds the cause, fixes it and pushes;
4. remembers each (PR, commit, failing set) in `~/.claude/hooks/failedci2claude.seen.json`, so a failure is reported once.

Every run appends one line to `~/.claude/hooks/failedci2claude.log`. If the hook seems silent, read that file: no line
means it never ran, a line saying `gh ...` means `gh` is missing or not signed in.

## What it does not do

It runs **when a turn ends**. A session that sits idle is not woken by a failure; for that, use the desktop app's
Auto-fix. The two complement each other.

## Test

```sh
pip install pytest && pytest tests
```

The tests run the real script against a temporary git repo with a stub `gh`; nothing touches the network or your
`~/.claude`.

## Landing page

`docs/index.html`, served by GitHub Pages from the `docs/` folder.

MIT licensed.
