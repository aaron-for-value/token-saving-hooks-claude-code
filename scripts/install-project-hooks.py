#!/usr/bin/env python3
"""Install token-saving hooks into a Codex project as project-local hooks."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path


def repo_root_from_script() -> Path:
    return Path(__file__).resolve().parents[1]


def detect_project_root(cwd: Path) -> Path:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=str(cwd),
            check=True,
            text=True,
            capture_output=True,
        )
        return Path(result.stdout.strip()).resolve()
    except Exception:
        return cwd.resolve()


def copy_tree(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def copy_runtime_scripts(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True, exist_ok=True)
    for item in src.iterdir():
        if item.name == "install-project-hooks.py":
            continue
        if item.is_dir():
            shutil.copytree(item, dst / item.name)
        else:
            shutil.copy2(item, dst / item.name)


def hooks_config(hook_dir: Path) -> dict:
    return {
        "hooks": {
            "UserPromptSubmit": [
                {
                    "hooks": [
                        {
                            "type": "command",
                            "command": f"python3 {hook_dir / 'user-prompt-submit.py'}",
                            "timeout": 5,
                        }
                    ]
                }
            ],
            "PreToolUse": [
                {
                    "matcher": "Read",
                    "hooks": [
                        {
                            "type": "command",
                            "command": f"bash {hook_dir / 'pre-tool-dedup.sh'}",
                        }
                    ],
                },
                {
                    "matcher": "Bash",
                    "hooks": [
                        {
                            "type": "command",
                            "command": f"bash {hook_dir / 'pre-bash-diff-guard.sh'}",
                        },
                        {
                            "type": "command",
                            "command": f"bash {hook_dir / 'pre-bash-dedup.sh'}",
                        },
                    ],
                },
            ],
            "PostToolUse": [
                {
                    "matcher": "Read",
                    "hooks": [
                        {
                            "type": "command",
                            "command": f"bash {hook_dir / 'post-tool-dedup.sh'}",
                        }
                    ],
                }
            ],
            "PreCompact": [
                {
                    "hooks": [
                        {
                            "type": "command",
                            "command": f"bash {hook_dir / 'precompact-snapshot.sh'}",
                            "timeout": 15,
                        }
                    ]
                }
            ],
            "SessionStart": [
                {
                    "hooks": [
                        {
                            "type": "command",
                            "command": f"bash {hook_dir / 'session-start-restore.sh'}",
                            "timeout": 5,
                        }
                    ]
                }
            ],
            "Stop": [
                {
                    "hooks": [
                        {
                            "type": "command",
                            "command": f"bash {hook_dir / 'stop-quality-gate.sh'}",
                        }
                    ]
                }
            ],
        }
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--project",
        default=".",
        help="Project directory to install into. Defaults to cwd or its git root.",
    )
    parser.add_argument(
        "--source",
        default=str(repo_root_from_script()),
        help="token-saving-hooks source directory.",
    )
    args = parser.parse_args()

    source = Path(args.source).expanduser().resolve()
    project = detect_project_root(Path(args.project).expanduser().resolve())
    target = project / ".codex/token-saving-hooks"
    hook_dir = target / "hooks"

    if not (source / "hooks/hooks.json").exists():
        raise SystemExit(f"missing Codex hooks source: {source / 'hooks/hooks.json'}")

    (project / ".codex").mkdir(parents=True, exist_ok=True)
    copy_tree(source / "hooks", hook_dir)
    copy_runtime_scripts(source / "scripts", target / "scripts")
    shutil.copy2(source / "README.md", target / "README.md")

    hooks_path = project / ".codex/hooks.json"
    hooks_path.write_text(
        json.dumps(hooks_config(hook_dir), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"installed project hooks: {hooks_path}")
    print(f"installed hook bundle: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
