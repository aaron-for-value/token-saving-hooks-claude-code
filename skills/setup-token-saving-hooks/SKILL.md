---
name: setup-token-saving-hooks
description: Initialize a project so token-saving-hooks can enforce diff compression, context snapshots, and test-output quality gates in Codex.
---

# Setup Token Saving Hooks

Use this skill when the user asks to set up, initialize, verify, or repair token-saving-hooks in the current Codex project.

## Workflow

1. Check that `git` exists with `git --version`.
   - If missing, stop and tell the user to install Git first.
2. Check whether the current directory is inside a Git repository with `git rev-parse --show-toplevel`.
   - If it fails, run `git init`.
3. Create `.codex/` if needed.
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
- Keep plugin state under `.codex/`.
