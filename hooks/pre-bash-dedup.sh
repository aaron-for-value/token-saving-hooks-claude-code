#!/bin/bash
# pre-bash-dedup.sh — Bash 纯查询命令去重（2 分钟内相同命令拦截）
find /tmp -name ".claude_bash_cache_*" -mtime +1 -delete 2>/dev/null

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
CACHE_FILE="/tmp/.claude_bash_cache_${SESSION_ID}"

# 只对纯查询命令去重，写操作、构建操作不受影响
if ! echo "$CMD" | grep -qE '^\s*(cat |head |tail |grep |find |ls |git log|git status|git diff --stat|git diff --name|pnpm test|npm test|yarn test)'; then
  exit 0
fi

# 生成命令指纹
CMD_HASH=$(echo "$CMD" | tr -d ' \t\n' | md5sum | cut -d' ' -f1)

if [ -f "$CACHE_FILE" ]; then
  LAST_TS=$(grep "^${CMD_HASH}:" "$CACHE_FILE" 2>/dev/null | tail -1 | cut -d: -f2)
  if [ -n "$LAST_TS" ]; then
    AGE=$(( $(date +%s) - LAST_TS ))
    if [ "$AGE" -lt 120 ]; then
      echo "SKIP: Identical command run ${AGE}s ago. Use previous output already in context." >&2
      exit 2
    fi
  fi
fi

# 更新缓存，只保留最近 100 条
echo "${CMD_HASH}:$(date +%s)" >> "$CACHE_FILE"
tail -100 "$CACHE_FILE" > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
exit 0
