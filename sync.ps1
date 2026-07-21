<#
  sync.ps1 — 实时增改文件后一键推送（触发 Cloudflare Pages 自动部署）
  用法：powershell -ExecutionPolicy Bypass -File sync.ps1
#>
$ErrorActionPreference = "Stop"
git add -A
$msg = Read-Host "提交说明（默认: update）"
if (-not $msg) { $msg = "update" }
git commit -m $msg
git push
Write-Host "`n✅ 已推送，Cloudflare Pages 将自动重新部署。`n" -ForegroundColor Green
