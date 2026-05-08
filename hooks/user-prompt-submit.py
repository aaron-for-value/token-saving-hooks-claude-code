#!/usr/bin/env python3
# user-prompt-submit.py — UserPromptSubmit hook（合并版）
# 职责1：读取 StatusLine 写入的 ctx 信号文件，>= 55% 时注入 /compact 指令
# 职责2：中英文双语冗余词压缩（原 user-prompt-compress.py 逻辑）

import json, sys, os, re, time

data = json.load(sys.stdin)
prompt = data.get("prompt", "")
session_id = data.get("session_id", "")

additional_parts = []

# ══════════════════════════════════════════════════════════════════
# 职责1：检测 ctx 使用率，>= 55% 时注入 /compact 指令
# ══════════════════════════════════════════════════════════════════
state_file = f"/tmp/.claude_ctx_pct_{session_id}"
if os.path.exists(state_file):
    try:
        pct = int(open(state_file).read().strip())
        # 防抖：同一 session 10 分钟内只触发一次
        flag_file = f"/tmp/.claude_compact_flag_{session_id}"
        should_trigger = True
        if os.path.exists(flag_file):
            age = time.time() - os.path.getmtime(flag_file)
            if age < 600:
                should_trigger = False

        if pct >= 55 and should_trigger:
            open(flag_file, 'w').close()
            # exit 2 阻止消息发送，stderr 直接显示给用户
            # Claude 无法执行 /compact（它是 CLI 斜杠命令），必须由用户手动输入
            sys.stderr.write(
                f"⚠️  Context 已达 {pct}%（阈值 55%），消息已暂停发送。\n"
                f"请先输入 /compact，compact 后再重新发送消息。\n"
                f"（可在 compact 前用一句话总结当前任务状态）\n"
            )
            sys.exit(2)
    except Exception:
        pass

# ══════════════════════════════════════════════════════════════════
# 职责2：中英文双语冗余词压缩
# ══════════════════════════════════════════════════════════════════
original_len = len(prompt)

# 阶段2：空白规范化
prompt = re.sub(r'\n{3,}', '\n\n', prompt)
prompt = re.sub(r'[ \t]+\n', '\n', prompt)
prompt = re.sub(r'[ \t]{2,}', ' ', prompt)
prompt = prompt.strip()

# 阶段1：高置信度拼写修正（英文）
typos = {
    r'\brecieve\b': 'receive',
    r'\boccured\b': 'occurred',
    r'\bseperate\b': 'separate',
    r'\bdefintely\b': 'definitely',
    r'\brefacter\b': 'refactor',
    r'\bimpliment\b': 'implement',
    r'\benviroment\b': 'environment',
    r'\bfunciton\b': 'function',
}
for pattern, fix in typos.items():
    prompt = re.sub(pattern, fix, prompt, flags=re.IGNORECASE)

# 英文冗余短语（~50条）
en_phrases = [
    (r'(?i)^(please\s+)?can you please\s+', ''),
    (r'(?i)^(please\s+)?could you please\s+', ''),
    (r'(?i)^(please\s+)?would you mind\s+', ''),
    (r'(?i)^i was wondering if you could\s+', ''),
    (r'(?i)^i would like you to\s+', ''),
    (r'(?i)^i need you to\s+', ''),
    (r'(?i)^i want you to\s+', ''),
    (r'(?i)^please help me to\s+', ''),
    (r'(?i)^please help me\s+', ''),
    (r'(?i)^could you help me\s+', ''),
    (r'(?i)^can you help me\s+', ''),
    (r'(?i)as an ai( language model)?,?\s*', ''),
    (r'(?i)as a large language model,?\s*', ''),
    (r'(?i)\bfeel free to\b\s*', ''),
    (r'(?i)\bplease make sure to\b', 'ensure'),
    (r'(?i)\bmake sure to\b', 'ensure'),
    (r'(?i)\bplease note that\b\s*', ''),
    (r'(?i)\bit is important to note that\b\s*', ''),
    (r'(?i)\bkindly\b\s*', ''),
    (r'(?i)\bbasically\b\s*', ''),
    (r'(?i)\bactually\b\s*', ''),
    (r'(?i)\bjust\s+(?=\w)', ''),
    (r'(?i)\bsimply\s+(?=\w)', ''),
    (r'(?i)\bgo ahead and\s+', ''),
    (r'(?i)\btry to\s+', ''),
    (r'(?i)^(please\s+)?can you\s+', ''),
    (r'(?i)^(please\s+)?could you\s+', ''),
    (r'(?i)^(please\s+)?would you\s+', ''),
    (r'(?i),?\s*please[.\s]*$', ''),
    (r'(?i),?\s*thank you[.\s]*$', ''),
    (r'(?i),?\s*thanks[.\s]*$', ''),
    (r'(?i)\bin order to\b', 'to'),
    (r'(?i)\bfor the purpose of\b', 'for'),
    (r'(?i)\bwith regard to\b', 'regarding'),
    (r'(?i)\bdue to the fact that\b', 'because'),
    (r'(?i)\bat this point in time\b', 'now'),
    (r'(?i)\bin the event that\b', 'if'),
    (r'(?i)\butilize\b', 'use'),
    (r'(?i)\bcommence\b', 'start'),
    (r'(?i)\bI think\s+', ''),
    (r'(?i)\bI believe\s+', ''),
    (r'(?i)\bI suppose\s+', ''),
    (r'(?i)\bmaybe\s+', ''),
    (r'(?i)\bperhaps\s+', ''),
]
for pattern, replacement in en_phrases:
    prompt = re.sub(pattern, replacement, prompt).strip()

# 中文冗余短语（~35条）
zh_phrases = [
    (r'^(请问\s*)?麻烦你\s*', ''),
    (r'^(请问\s*)?能不能\s*', ''),
    (r'^(请问\s*)?可以\s*帮我\s*', ''),
    (r'^(请问\s*)?你能\s*帮我\s*', ''),
    (r'^请你\s*', ''),
    (r'^帮我\s*', ''),
    (r'^请帮我\s*', ''),
    (r'^麻烦帮我\s*', ''),
    (r'^我想让你\s*', ''),
    (r'^我需要你\s*', ''),
    (r'^我希望你\s*', ''),
    (r'^我想请你\s*', ''),
    (r'^劳烦\s*', ''),
    (r'作为一个AI(语言模型)?,?\s*', ''),
    (r'\b我觉得\s*', ''),
    (r'\b我认为\s*', ''),
    (r'\b我感觉\s*', ''),
    (r'\b基本上\s*', ''),
    (r'\b其实\s*', ''),
    (r'\b事实上\s*', ''),
    (r'\b说实话\s*', ''),
    (r'\b简单来说\s*', ''),
    (r'\b总的来说\s*', ''),
    (r'\b也就是说\s*', ''),
    (r'\b换句话说\s*', ''),
    (r',?\s*谢谢[。！.!]?\s*$', ''),
    (r',?\s*感谢[你您][。！.!]?\s*$', ''),
    (r',?\s*麻烦了[。！.!]?\s*$', ''),
    (r'为了(?=实现|达到|完成|做)', ''),
    (r'通过使用\s*', '使用'),
    (r'进行\s*(?=修改|更新|删除|添加|检查)', ''),
    (r'对其进行\s*', ''),
    (r'对此进行\s*', ''),
]
for pattern, replacement in zh_phrases:
    prompt = re.sub(pattern, replacement, prompt).strip()

# 最终清理
prompt = re.sub(r'[ \t]{2,}', ' ', prompt)
prompt = re.sub(r'\n{3,}', '\n\n', prompt)
prompt = prompt.strip()

saved = original_len - len(prompt)
if saved > 10:
    additional_parts.append(f"[Prompt compressed: -{saved} chars]\n{prompt}")

# ══════════════════════════════════════════════════════════════════
# 输出
# ══════════════════════════════════════════════════════════════════
if additional_parts:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": "\n\n---\n\n".join(additional_parts)
        }
    }, ensure_ascii=False))

sys.exit(0)
