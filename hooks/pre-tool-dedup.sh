#!/bin/bash
# pre-tool-dedup.sh — Read 去重，查缓存阶段（只读不写）
# 写缓存由 post-tool-dedup.sh 在 PostToolUse 完成
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

token_saving_cleanup_cache "read"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | token_saving_session_id)
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')
CACHE_KEY="${AGENT_ID:-$SESSION_ID}"
CACHE_FILE=$(token_saving_cache_file "read" "$CACHE_KEY")
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // ""')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 分段读取（有 offset 参数且不为 0）直接放行
OFFSET=$(echo "$INPUT" | jq -r '.tool_input.offset // .tool_input.start_line // "0"')
if [ "$OFFSET" != "0" ] && [ "$OFFSET" != "null" ] && [ -n "$OFFSET" ]; then
  exit 0
fi

# 计算文件指纹（mtime:size），macOS 和 Linux 均兼容
FINGERPRINT=$(stat -f "%m:%z" "$FILE_PATH" 2>/dev/null || stat -c "%Y:%s" "$FILE_PATH" 2>/dev/null || echo "0:0")

# 查找缓存中该路径的记录
CACHED_LINE=$(grep -F "${FILE_PATH}|" "$CACHE_FILE" 2>/dev/null | head -1)

if [ -n "$CACHED_LINE" ]; then
  CACHED_FP="${CACHED_LINE##*|}"
  if [ "$CACHED_FP" = "$FINGERPRINT" ]; then
    echo "SKIP: $FILE_PATH already read this session (content unchanged). Use cached knowledge instead of re-reading." >&2
    exit 2
  else
    # 指纹不同 → 文件已变更，移除旧记录，放行本次读取（post hook 会写入新指纹）
    grep -vF "${FILE_PATH}|" "$CACHE_FILE" > "${CACHE_FILE}.tmp" 2>/dev/null
    mv "${CACHE_FILE}.tmp" "$CACHE_FILE" 2>/dev/null
  fi
fi

exit 0
