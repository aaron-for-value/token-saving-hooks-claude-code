#!/bin/bash
# post-tool-dedup.sh — Read 去重，写缓存阶段
# 只在 Read 工具成功执行后写入，避免"拦截后误记录"问题

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')

if [ "$TOOL" != "Read" ]; then
  exit 0
fi

# 检查工具是否成功（tool_response 不含 error 字段）
ERROR=$(echo "$INPUT" | jq -r '.tool_response.error // ""')
if [ -n "$ERROR" ]; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')
CACHE_KEY="${AGENT_ID:-$SESSION_ID}"
CACHE_FILE="/tmp/.claude_read_cache_${CACHE_KEY}"
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // ""')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 分段读取直接放行，不写缓存（pre hook 也不拦截）
OFFSET=$(echo "$INPUT" | jq -r '.tool_input.offset // .tool_input.start_line // "0"')
if [ "$OFFSET" != "0" ] && [ "$OFFSET" != "null" ] && [ -n "$OFFSET" ]; then
  exit 0
fi

FINGERPRINT=$(stat -f "%m:%z" "$FILE_PATH" 2>/dev/null || stat -c "%Y:%s" "$FILE_PATH" 2>/dev/null || echo "0:0")
echo "${FILE_PATH}|${FINGERPRINT}" >> "$CACHE_FILE"
exit 0
