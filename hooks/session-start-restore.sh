#!/bin/bash
# session-start-restore.sh — SessionStart hook
# 仅在 /compact 后恢复上下文，/clear 和首次启动不触发
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // ""')
CWD=$(echo "$INPUT" | token_saving_cwd)
SESSION_ID=$(echo "$INPUT" | token_saving_session_id)

# 只在 compact 后恢复，/clear（source="clear"）和 startup 不恢复
if [ "$SOURCE" != "compact" ]; then
  exit 0
fi

PROJECT_DIR="$(token_saving_project_dir_name)"
SNAPSHOT="$CWD/$PROJECT_DIR/CONTEXT-SNAPSHOT.md"
if [ ! -f "$SNAPSHOT" ]; then
  exit 0
fi

# compact 后清除 ctx 信号文件，避免 user-prompt-submit.py 读到 compact 前的旧值
rm -f "$(token_saving_ctx_file "$SESSION_ID")"
rm -f "$(token_saving_compact_flag_file "$SESSION_ID")"

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
