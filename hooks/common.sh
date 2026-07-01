#!/bin/bash

token_saving_host() {
  echo "codex"
}

token_saving_state_prefix() {
  echo "codex"
}

token_saving_project_dir_name() {
  echo ".codex"
}

token_saving_session_id() {
  jq -r '.session_id // .sessionId // "default"'
}

token_saving_tool_name() {
  jq -r '.tool_name // .toolName // .tool // ""'
}

token_saving_cwd() {
  jq -r '.cwd // .working_directory // .workingDirectory // ""'
}

token_saving_cache_file() {
  local kind="$1"
  local key="$2"
  local prefix
  prefix="$(token_saving_state_prefix)"
  echo "/tmp/.${prefix}_${kind}_cache_${key:-default}"
}

token_saving_ctx_file() {
  local session_id="$1"
  local prefix
  prefix="$(token_saving_state_prefix)"
  echo "/tmp/.${prefix}_ctx_pct_${session_id:-default}"
}

token_saving_compact_flag_file() {
  local session_id="$1"
  local prefix
  prefix="$(token_saving_state_prefix)"
  echo "/tmp/.${prefix}_compact_flag_${session_id:-default}"
}

token_saving_cleanup_cache() {
  local kind="$1"
  local prefix
  prefix="$(token_saving_state_prefix)"
  find /tmp -name ".${prefix}_${kind}_cache_*" -mtime +1 -delete 2>/dev/null
}
