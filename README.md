# token-saving-hooks

A Codex plugin that reduces token consumption through lifecycle hooks.

| Hook | Trigger | Effect |
|---|---|---|
| Read dedup | Read same file twice in a session | Blocks re-read if content unchanged |
| Bash diff guard | `git diff` without compression | Blocks and requires piping through `compress-diff.sh` |
| Bash dedup | Identical query command repeated | Blocks duplicate execution |
| Context snapshot | `/compact` via PreCompact | Saves context snapshot before compaction |
| Session restore | SessionStart after compact | Restores snapshot if one exists |
| Quality gate | Stop | Checks recent test output for failures |
| Ctx auto-compact | UserPromptSubmit when ctx >= 55% | Blocks message and asks the user to `/compact` first |
| Prompt compression | UserPromptSubmit | Adds a compressed prompt variant as hook context |

## Installation

Requirements: Codex app or CLI with plugin support, Git, Bash, Python 3, and `jq`.

Add this repository as a Codex marketplace, then install the plugin:

```bash
codex plugin marketplace add https://github.com/aaron-for-value/token-saving-hooks-claude-code
codex plugin add token-saving-hooks@token-saving-hooks-marketplace
```

Start a new Codex thread after installing so the plugin-bundled hooks are picked up. Codex may ask you to review and trust the hook definitions before non-managed command hooks run.

## Plugin Layout

- `.codex-plugin/plugin.json`
- `.agents/plugins/marketplace.json`
- `hooks/hooks.json`
- `hooks/*.sh`
- `hooks/user-prompt-submit.py`
- `skills/setup-token-saving-hooks/SKILL.md`

## Project Conventions

Codex state is written under `.codex/` in each project and `/tmp/.codex_*` cache files.

For test-output quality gates, write recent test logs to:

```bash
.codex/last_test_output.txt
```

For example:

```bash
pnpm test 2>&1 | tee .codex/last_test_output.txt
```

For diff compression, use:

```bash
git diff | bash "$(git rev-parse --show-toplevel)/path/to/token-saving-hooks/scripts/compress-diff.sh"
```

When the plugin is installed through Codex, the hook warning prints the installed plugin path to `compress-diff.sh`.

## Setup Skill

After installing the plugin, ask Codex:

```text
Use setup-token-saving-hooks for this project.
```

The skill checks Git, initializes a repository if needed, creates `.codex/`, and stages existing non-hidden files so `git diff` has a baseline.

## Known Limitations

- Windows without WSL is not supported because hooks are Bash + Python scripts.
- Context percentage enforcement depends on Codex exposing context usage to `UserPromptSubmit`, or another signal file at `/tmp/.codex_ctx_pct_<session_id>`. Prompt compression still works without that signal.
- The Bash diff guard strips simple quoted strings before scanning for `git diff`, but escaped quotes inside strings may still cause a false positive.
