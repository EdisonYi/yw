#!/usr/bin/env bash
# yw skill 一键部署脚本（bash / Git Bash / Linux / macOS）
# 用法: bash deploy.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 部署目标：优先 $WORKBUDDY_SKILLS，否则默认用户级 skills 目录
if [ -n "${WORKBUDDY_SKILLS:-}" ]; then
  TARGET="$WORKBUDDY_SKILLS/yw"
else
  TARGET="$HOME/.workbuddy/skills/yw"
fi

echo "==> 部署源: $SCRIPT_DIR"
echo "==> 部署目标: $TARGET"

mkdir -p "$TARGET/references"
# 复制 skill 本体（SKILL.md + references/），不复制 README / 部署脚本自身
cp "$SCRIPT_DIR/SKILL.md" "$TARGET/SKILL.md"
( cd "$SCRIPT_DIR/references" && tar cf - . ) | ( cd "$TARGET/references" && tar xf - )

echo "✅ yw skill 已部署到: $TARGET"
echo ""
echo "   触发方式: 在 WorkBuddy 对话中输入  /yw  或  @skill:yw"
echo "   直接描述运维问题即可，例如: '服务器起不来' / '帮查 9088 端口' / '部署后服务报错'"
echo "   部署后立即生效（若用 /install-github-skill 安装，重启一次会话即可）。"
