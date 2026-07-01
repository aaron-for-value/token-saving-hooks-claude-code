# Claude to Codex Migration Package

This is the recommended shape for migrating a Claude-heavy project to Codex without flattening memories into `AGENTS.md`.

## Principle

Keep durable rules separate from recalled context:

- `AGENTS.md`: project rules, commands, verification expectations, and workflow constraints that must always apply.
- `.codex/memories/`: project-level memory documents imported from Claude project memory.
- `.codex/hooks.json` or a plugin hook: optional lifecycle glue that injects a concise memory index or selected memory files.

Do not paste Claude memory into `AGENTS.md`. Memory is context, not policy.

## Project Layout

For each migrated project:

```text
<project>/
  AGENTS.md
  .codex/
    memories/
      README.md
      claude-import/
        MEMORY.md
        project_*.md
        feedback_*.md
        reference_*.md
      index.md
    last_test_output.txt
```

`index.md` should be generated from the imported memory filenames and short headings. It is the file a SessionStart hook can inject first.

## Import Mapping

Claude project memory source:

```text
~/.claude/projects/<encoded-project-path>/memory/*.md
```

Codex project memory destination:

```text
<project>/.codex/memories/claude-import/*.md
```

Keep original filenames. Do not merge them unless there are duplicates.

## Runtime Strategy

Codex memories are generated local state under `~/.codex/memories/`, but project migration needs repo-local portability. Treat `.codex/memories/` as project documentation and use a hook or skill to surface it:

1. On `SessionStart`, inject `.codex/memories/index.md` if present.
2. If the user asks about project history, read the specific memory file from `.codex/memories/claude-import/`.
3. Keep `AGENTS.md` short and authoritative; link to `.codex/memories/index.md` only as optional context.

## Suggested Hook

A small project hook can load the index without forcing every memory file into every thread:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "bash .codex/hooks/session-start-project-memory.sh",
            "statusMessage": "Loading project memory index"
          }
        ]
      }
    ]
  }
}
```

The hook should emit `hookSpecificOutput.additionalContext` with the index only. Full memory files should stay on disk until needed.

## Migration Steps

1. Detect projects under the user's configured works root, for example `<home>/works`.
2. Map each project to its Claude memory folder by encoded path.
3. Create `<project>/.codex/memories/claude-import/`.
4. Copy memory Markdown files unchanged.
5. Generate `.codex/memories/index.md`.
6. Add or update project `.codex/hooks.json` only if the project should auto-inject the index.
7. Leave `AGENTS.md` limited to rules and links.

## Uninstall Boundary

After this package is applied and verified, Claude memory folders become backup material rather than runtime dependencies.
