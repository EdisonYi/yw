# yw skill 一键部署脚本（PowerShell / Windows）
# 用法: powershell -ExecutionPolicy Bypass -File deploy.ps1
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Src = Join-Path $ScriptDir 'yw'

# 部署目标：优先 $env:WORKBUDDY_SKILLS，否则默认用户级 skills 目录
if ($env:WORKBUDDY_SKILLS) {
  $Target = Join-Path $env:WORKBUDDY_SKILLS 'yw'
} else {
  $Target = Join-Path $env:USERPROFILE '.workbuddy/skills/yw'
}

Write-Host "==> 部署源: $Src"
Write-Host "==> 部署目标: $Target"

New-Item -ItemType Directory -Force -Path $Target | Out-Null
Copy-Item -Path "$Src\*" -Destination $Target -Recurse -Force

Write-Host "✅ yw skill 已部署到: $Target"
Write-Host ""
Write-Host "   触发方式: 在 WorkBuddy 对话中输入  /yw  或  @skill:yw"
Write-Host "   直接描述运维问题即可，例如: '服务器起不来' / '帮查 9088 端口' / '部署后服务报错'"
Write-Host "   无需重启 WorkBuddy，部署后立即生效。"
