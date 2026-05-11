# token-saving-hooks

A Claude Code plugin that reduces token consumption through automated hooks:

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

### Step 1: Add marketplace

```
/plugin marketplace add https://github.com/aaron-for-value/token-saving-hooks-claude-code
```

### Step 2: Install plugin

```
/plugin install token-saving-hooks@token-saving-hooks-marketplace
```

### Step 3: Reload

```
/reload-plugins
```

### Step 4: Setup (first time per project)

Run in your project directory:

```
/setup
```

This checks that Git is available and initializes a repo if needed. The hooks rely on `git rev-parse` to locate the project root — the project must be a Git repo.

### Optional: Status line

Add to `~/.claude/settings.json` or `.claude/settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh"
}
```

### Using compress-diff

When Claude runs `git diff`, it will be blocked unless piped through the compression script:

```bash
git diff | bash "${CLAUDE_PLUGIN_ROOT}/scripts/compress-diff.sh"
```

---

## Known limitations

- Windows: hooks are bash + Python scripts. Native Windows (no WSL) is not supported.
- Codex: see [Codex installation](#installation--codex) below (coming soon).
