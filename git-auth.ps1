<#
  git-auth.ps1 — 通过 Git Credential Manager 网页授权登录 GitHub，以便提交代码
  用法：
    powershell -ExecutionPolicy Bypass -File git-auth.ps1
#>

Write-Host "`n=== 1/3  配置 Git 使用网页授权 (Credential Manager) ===" -ForegroundColor Cyan
git config --global credential.helper manager
Write-Host "  已设置 credential.helper = manager（push 时会弹浏览器登录）" -ForegroundColor Green

Write-Host "`n=== 2/3  配置代理（解决连接 GitHub 被重置）===" -ForegroundColor Cyan
$proxy = Read-Host "  如直连 GitHub 会 'Connection was reset'，请输入代理地址（例 http://127.0.0.1:7890，留空跳过）"
if ($proxy.Trim()) {
    git config --global http.proxy $proxy.Trim()
    git config --global https.proxy $proxy.Trim()
    Write-Host "  已配置代理: $($proxy.Trim())" -ForegroundColor Green
} else {
    Write-Host "  跳过代理配置。" -ForegroundColor Yellow
}

Write-Host "`n=== 3/3  触发 GitHub 网页授权 ===" -ForegroundColor Cyan
Write-Host "  接下来会弹出浏览器，请登录 GitHub 并点授权。" -ForegroundColor Yellow
$repo = Read-Host "  请输入仓库 HTTPS 地址（留空用默认 https://github.com/AMDSE/0712121.xyz）"
if (-not $repo.Trim()) { $repo = "https://github.com/AMDSE/0712121.xyz" }

try {
    git ls-remote $repo HEAD
    Write-Host "`n✅ 认证完成！现在可以直接提交并推送了：" -ForegroundColor Green
} catch {
    Write-Host "`n⚠️ 触发授权失败，多半是网络未连通。请确认代理已配置并能打开 github.com，然后重跑本脚本。" -ForegroundColor Red
}

Write-Host "  git add -A" -ForegroundColor White
Write-Host "  git commit -m 'update'" -ForegroundColor White
Write-Host "  git push origin main" -ForegroundColor White
Write-Host ""
