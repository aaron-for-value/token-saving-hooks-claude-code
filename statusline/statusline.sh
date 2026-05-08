#!/bin/bash
# statusline.sh — StatusLine hook
# 职责1：渲染状态栏（保持你现有的 "Model | in=X, out=Y | ctx [bar] Z%" 格式）
# 职责2：把 used_percentage 写入信号文件，供 UserPromptSubmit 读取

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
IN_TOKENS=$(echo "$INPUT" | jq -r '.context_window.current_usage.input_tokens // 0')
OUT_TOKENS=$(echo "$INPUT" | jq -r '.context_window.current_usage.output_tokens // 0')
PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# ── 写信号文件（供 UserPromptSubmit 读取）──────────────────────
STATE_FILE="/tmp/.claude_ctx_pct_${SESSION_ID}"
echo "$PCT" > "$STATE_FILE"

# ── 进度条渲染（与你现有格式一致）──────────────────────────────
BAR_WIDTH=10
FILLED=$(( PCT * BAR_WIDTH / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '▓')
[ "$EMPTY"  -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# 55% 以上加警告
if [ "$PCT" -ge 55 ]; then
  WARN=" ⚠️"
else
  WARN=""
fi

echo "${MODEL} | in=${IN_TOKENS}, out=${OUT_TOKENS} | ctx [${BAR}] ${PCT}%${WARN}"
