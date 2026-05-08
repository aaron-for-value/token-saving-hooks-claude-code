#!/bin/bash
# session-start-restore.sh — SessionStart hook
# 仅在 /compact 后恢复上下文，/clear 和首次启动不触发

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

# 只在 compact 后恢复，/clear（source="clear"）和 startup 不恢复
if [ "$SOURCE" != "compact" ]; then
  exit 0
fi

SNAPSHOT="$CWD/.claude/CONTEXT-SNAPSHOT.md"
if [ ! -f "$SNAPSHOT" ]; then
  exit 0
fi

# compact 后清除 ctx 信号文件，避免 user-prompt-submit.py 读到 compact 前的旧值
rm -f "/tmp/.claude_ctx_pct_${SESSION_ID}"
rm -f "/tmp/.claude_compact_flag_${SESSION_ID}"

# 直接让 Python 读文件，避免 shell 变量传递特殊字符的注入风险
python3 - "$SNAPSHOT" <<'PYEOF'
import sys, json, os

snapshot_path = sys.argv[1]
try:
    with open(snapshot_path, 'r') as f:
        content = f.read()
    os.remove(snapshot_path)
except Exception as e:
    sys.exit(0)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "## 上次会话摘要（/compact 前自动保存）\n\n" + content
    }
}))
PYEOF

exit 0
