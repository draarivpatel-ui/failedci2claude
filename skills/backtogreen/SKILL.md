---
name: backtogreen
description: Make the session that opened a pull request responsible for its CI. Find the failing checks with gh, work out whose failure it is, fix it in the PR's own worktree and push, and set up the failedci2claude Stop hook so the session is told when CI fails. Use when a pull request of yours has a red check, or when asked to watch or fix CI.
license: MIT
compatibility: Requires the gh CLI signed in (gh auth login) and git. The optional hook needs python3 and edits ~/.claude/settings.json.
metadata:
  author: failedci2claude
  version: "1.0"
---

# backtogreen

The session that opened a pull request owns its CI. A skill only runs when it is called, so it cannot notice a failure by itself: use the steps below when you know CI is red, and the hook (last section) so the session is told.

## Fix a red check

1. See what failed, on the PR's own head:
   `gh pr checks <number>`, then `gh run view --job <job-id> --log-failed`.
   Logs are not available while the run is still in progress: wait, or read one finished job with `gh api repos/<owner>/<repo>/actions/jobs/<job-id>/logs`.
2. Compare the head the failure names with your own `git rev-parse HEAD`. A failure from a head you already replaced is stale: re-check it, do not "fix" it.
3. Decide whose failure it is before editing:
   - Does the base branch fail the same check? Run the failing command on the base branch in a clean worktree. If it does, the fix belongs in its own pull request, not in this one.
   - A `Server Error` from the GitHub API or a registry 5xx is transient: `gh run rerun <run-id> --failed`, no code change.
   - A check that wants a test for every changed product file (some repos have one): add the test, do not exempt the file.
4. Fix it in the worktree of that PR's branch, not in a shared checkout whose branch other sessions may switch.
5. Run the checks for the files you touched, commit, and push to the PR branch. Merge the base branch into the PR branch when they conflict; do not rebase or force-push a branch others use.
6. Before `git commit --amend`, run `git status`: after a merge that did nothing, an amend rewrites the previous commit and the push is rejected.

## Resolve a merge conflict

A conflict keeps a pull request from going green even when every check passes. In the PR's worktree: `git fetch <remote> <base>`, then `git merge FETCH_HEAD` (the remote that points at the repository, not a stale local copy of the base). Resolve keeping the intent of both sides, run the checks for the files you touched, commit and push. Ask only if a conflict needs a product decision. Never rebase or force-push a branch others use. If `git merge` says "Already up to date" but GitHub still shows a conflict, the event was for an older head: re-check.

## Be told when CI fails

- **The desktop app's Auto-fix** (Claude desktop app) wakes an idle session on CI failures, merge conflicts and review comments. Turn it on per pull request. This is the one that works while you are away.
- **The failedci2claude Stop hook** (https://backtogreen.flisk.si) tells the session when a turn ends and one of your open pull requests has a failed check or a merge conflict. It runs when a turn ends, so it cannot wake an idle session. It reads your pull requests with one `gh pr list` call and reports each failure once.

Install the hook only after the user agrees, because it edits `~/.claude/settings.json`:

```sh
git clone https://github.com/flisk-sh/failedci2claude && cd failedci2claude && ./install.sh
```

Hooks load when a session starts, so open a new session afterwards. To check that it ran, read `~/.claude/hooks/failedci2claude.log`: no line means it never ran; a line naming `gh` means `gh` is missing or not signed in.
