# token-saving-hooks

A Claude Code and Codex plugin that reduces token consumption through automated hooks:

| Hook | Trigger | Effect |
|---|---|---|
| Read dedup | Read same file twice in a session | Blocks re-read if content unchanged |
| Bash diff guard | `git diff` without compression | Blocks and requires piping through `compress-diff.sh` |
| Bash dedup | Identical bash command repeated | Blocks duplicate execution |
| Context snapshot | `/compact` (PreCompact) | Saves context snapshot before compaction |
| Session restore | Session start | Restores snapshot if one exists |
| Quality gate | Session stop | Checks last test output for failures |
| Ctx auto-compact | User message when ctx ≥ 55% | Blocks message, prompts user to `/compact` first |

---

## Installation — Claude Code

**Requirements:** Claude Code v2.1.92+, Git installed on your machine.

Project-level installation is recommended — the plugin config is stored in `.claude/settings.json` and shared with your team automatically when they clone the repo.

### Step 1 & 2: Add marketplace and install plugin

Run the following in your **terminal** from the project directory (not inside Claude Code):

```bash
claude plugin marketplace add https://github.com/aaron-for-value/token-saving-hooks-claude-code --scope project
claude plugin install token-saving-hooks@token-saving-hooks-marketplace --scope project
```

![Terminal showing plugin install](docs/iShot_2026-05-11_15.43.01.png)

### Step 3: Reload plugins

Run inside **Claude Code**:

```
/reload-plugins
```

### Step 4: Setup (first time per project)

Run inside **Claude Code**:

```
/setup
```

This checks that Git is available and initializes a repo if needed. It also stages existing non-hidden files so `git diff` has a baseline to work with.

![/setup command in Claude Code](docs/iShot_2026-05-11_15.42.46.png)

![/setup execution result](docs/iShot_2026-05-11_15.42.38.png)

### Optional: Status line

Add to `.claude/settings.json` (project) or `~/.claude/settings.json` (global):

```json
"statusLine": {
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh"
}
```

---

## Installation — Codex

**Requirements:** Codex app or CLI with plugin support, Git, Bash, Python 3, `jq`.

Add this repository as a Codex marketplace, then install the plugin:

```bash
codex plugin marketplace add https://github.com/aaron-for-value/token-saving-hooks-claude-code
codex plugin add token-saving-hooks@token-saving-hooks-marketplace
```

Start a new Codex thread after installing so the plugin-bundled hooks are picked up. Codex will ask you to review and trust the hook definitions before non-managed command hooks run.

The Codex plugin uses:

- `.codex-plugin/plugin.json`
- `.agents/plugins/marketplace.json`
- `hooks/hooks.json`

Codex state is written under `.codex/` in each project and `/tmp/.codex_*` cache files. Claude Code state remains under `.claude/` and `/tmp/.claude_*`.

### Codex project conventions

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

---

## Known limitations

- **Windows**: hooks are Bash + Python scripts. Native Windows without WSL is not supported.
- **Codex status line**: Codex does not use the Claude Code `statusLine` setting. Prompt auto-compact still works when a compatible context-percentage signal exists; otherwise the prompt-compression part still runs and context percentage enforcement is skipped.
- **Bash diff guard — escaped quotes**: The guard strips `"..."` and `'...'` content before scanning for `git diff`, so commit messages containing `git diff` no longer trigger false positives. However, escaped quotes inside strings (e.g. `git commit -m "fix \"git diff\" output"`) are not handled — the inner escaped quote will not be stripped and may still cause a false positive.
