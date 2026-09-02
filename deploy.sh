#!/usr/bin/env bash
# yw skill 一键部署脚本（bash / Git Bash / Linux / macOS）
# 用法: bash deploy.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/yw"

# 部署目标：优先 $WORKBUDDY_SKILLS，否则默认用户级 skills 目录
if [ -n "${WORKBUDDY_SKILLS:-}" ]; then
  TARGET="$WORKBUDDY_SKILLS/yw"
else
  TARGET="$HOME/.workbuddy/skills/yw"
fi

echo "==> 部署源: $SRC"
echo "==> 部署目标: $TARGET"

mkdir -p "$TARGET"
# 用 tar 整体复制（含嵌套目录），避免 cp 跨平台 glob 差异
( cd "$SRC" && tar cf - . ) | ( cd "$TARGET" && tar xf - )

echo "✅ yw skill 已部署到: $TARGET"
echo ""
echo "   触发方式: 在 WorkBuddy 对话中输入  /yw  或  @skill:yw"
echo "   直接描述运维问题即可，例如: '服务器起不来' / '帮查 9088 端口' / '部署后服务报错'"
echo "   无需重启 WorkBuddy，部署后立即生效。"
