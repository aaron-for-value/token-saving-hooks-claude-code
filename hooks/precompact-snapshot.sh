#!/bin/bash
# precompact-snapshot.sh — PreCompact hook：压缩前保存会话摘要到 CONTEXT-SNAPSHOT.md

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

SNAPSHOT="$CWD/.claude/CONTEXT-SNAPSHOT.md"
mkdir -p "$(dirname "$SNAPSHOT")"

python3 - "$TRANSCRIPT" "$SNAPSHOT" <<'PYEOF'
import sys, json

transcript_path = sys.argv[1]
snapshot_path = sys.argv[2]

entries = []
try:
    with open(transcript_path) as f:
        lines = [l.strip() for l in f.readlines() if l.strip()]

    for line in lines[-150:]:
        try:
            msg = json.loads(line)
            if not msg.get("message"):
                continue
            role = msg.get("type", "")
            content = msg["message"].get("content", "")

            if role == "user":
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    text = " ".join(
                        c.get("text", "") for c in content
                        if isinstance(c, dict) and c.get("type") == "text"
                    )
                else:
                    text = ""
                if text.strip():
                    entries.append(f"[User] {text[:400]}")

            elif role == "assistant" and isinstance(content, list):
                texts = [c["text"][:300] for c in content
                         if c.get("type") == "text" and c.get("text")]
                tools = [f"[{c['name']}]" for c in content
                         if c.get("type") == "tool_use"]
                summary = (" ".join(texts[:1]) + " " + " ".join(tools)).strip()
                if summary:
                    entries.append(f"[Assistant] {summary}")
        except Exception:
            continue

output = "\n\n".join(entries)
if len(output) > 12000:
    output = "...(earlier truncated)...\n\n" + output[-12000:]

with open(snapshot_path, "w") as f:
    f.write("# Pre-Compact Context Snapshot\n\n")
    f.write(output)
    f.write("\n")
PYEOF

exit 0
