# yw skill 一键部署脚本（PowerShell / Windows）
# 用法: powershell -ExecutionPolicy Bypass -File deploy.ps1
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 部署目标：优先 $env:WORKBUDDY_SKILLS，否则默认用户级 skills 目录
if ($env:WORKBUDDY_SKILLS) {
  $Target = Join-Path $env:WORKBUDDY_SKILLS 'yw'
} else {
  $Target = Join-Path $env:USERPROFILE '.workbuddy/skills/yw'
}

Write-Host "==> 部署源: $ScriptDir"
Write-Host "==> 部署目标: $Target"

New-Item -ItemType Directory -Force -Path (Join-Path $Target 'references') | Out-Null
# 复制 skill 本体（SKILL.md + references/），不复制 README / 部署脚本自身
Copy-Item -Path (Join-Path $ScriptDir 'SKILL.md') -Destination $Target -Force
Copy-Item -Path (Join-Path $ScriptDir 'references\*') -Destination (Join-Path $Target 'references') -Recurse -Force

Write-Host "✅ yw skill 已部署到: $Target"
Write-Host ""
Write-Host "   触发方式: 在 WorkBuddy 对话中输入  /yw  或  @skill:yw"
Write-Host "   直接描述运维问题即可，例如: '服务器起不来' / '帮查 9088 端口' / '部署后服务报错'"
Write-Host "   部署后立即生效（若用 /install-github-skill 安装，重启一次会话即可）。"
