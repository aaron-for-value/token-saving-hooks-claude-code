---
name: setup-token-saving-hooks
description: Initialize or verify project-local token-saving-hooks so they can enforce diff compression, context snapshots, and test-output quality gates in Codex.
---

# Setup Token Saving Hooks

Use this skill when the user asks to set up, initialize, verify, or repair project-local token-saving-hooks in the current Codex project.

## Workflow

1. Check that `git` exists with `git --version`.
   - If missing, stop and tell the user to install Git first.
2. Check whether the current directory is inside a Git repository with `git rev-parse --show-toplevel`.
   - If it fails, run `git init`.
3. Verify `.codex/hooks.json` exists and points at project-local `.codex/token-saving-hooks/` scripts. If it does not, run this repository's installer from the token-saving-hooks source checkout:

```bash
python3 scripts/install-project-hooks.py --project "$(git rev-parse --show-toplevel)"
```

4. Stage existing non-hidden files so `git diff` has a baseline:

```bash
find . -maxdepth 5 -type f -not -path './.git/*' -not -name '.*' -not -path '*/.*' 2>/dev/null | head -200 | xargs git add -- 2>/dev/null; true
```

5. Tell the user:
   - If `git init` ran: `Initialized a new Git repository and staged existing files. token-saving-hooks is ready for Codex.`
   - Otherwise: `Git repo detected. Staged any untracked non-hidden files. token-saving-hooks is ready for Codex.`

## Conventions

- Write test logs to `.codex/last_test_output.txt`.
- Use `git diff --stat`, `git diff --name-only`, `git diff -U0`, or pipe full diffs through `scripts/compress-diff.sh`.
- Keep hook state under `.codex/`.
- Prefer project-local `.codex/hooks.json` over a global plugin hook to avoid double triggering.
