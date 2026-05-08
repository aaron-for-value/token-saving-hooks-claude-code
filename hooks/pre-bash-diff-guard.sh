#!/bin/bash
# pre-bash-diff-guard.sh — git diff 强制压缩（排除统计类参数）
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if echo "$CMD" | grep -qE '\bgit\s+diff\b'; then
  # 放行：只看统计/文件名，输出量本身已经很小
  if echo "$CMD" | grep -qE '\-\-(stat|name-only|name-status|shortstat)'; then
    exit 0
  fi
  # 放行：已经压缩过
  if echo "$CMD" | grep -q 'compress-diff'; then
    exit 0
  fi
  # 放行：已经用 --unified=0 或 -U0（极简上下文）
  if echo "$CMD" | grep -qE '\-\-unified=0|\-U0'; then
    exit 0
  fi
  echo "BLOCK: git diff must be piped through compress-diff.sh to reduce token usage. Use: git diff ... | bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/compress-diff.sh\"" >&2
  exit 2
fi

exit 0
