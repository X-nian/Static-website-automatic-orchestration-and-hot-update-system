<#
  setup.ps1 — 一键配置「GitHub 仓库 + Cloudflare Pages 实时部署」环境
  在项目目录中运行：
    powershell -ExecutionPolicy Bypass -File setup.ps1
#>
$ErrorActionPreference = "Stop"

function Need($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

Write-Host "`n=== 步骤 1/4  安装工具链 (git / node / gh) ===" -ForegroundColor Cyan
if (-not (Need winget)) { Write-Error "未找到 winget，请先安装 Microsoft App Installer。"; exit 1 }

foreach ($p in @(
    @{ id = "Git.Git";           bin = "git" },
    @{ id = "OpenJS.NodeJS.LTS"; bin = "node" },
    @{ id = "GitHub.cli";        bin = "gh" }
)) {
    if (Need $p.bin) { Write-Host "  $($p.bin) 已存在，跳过。" -ForegroundColor Green }
    else { Write-Host "  安装 $($p.bin) ..." -ForegroundColor Yellow; winget install -e --source winget --scope user $p.id }
}
# 刷新 PATH，使后续命令能立即找到新装的工具
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "`n=== 步骤 2/4  GitHub 登录 (gh 浏览器授权) ===" -ForegroundColor Cyan
if (gh auth status 2>$null) { Write-Host "  已登录 GitHub。" -ForegroundColor Green }
else { Write-Host "  请在弹出的浏览器中完成授权..." -ForegroundColor Yellow; gh auth login }

Write-Host "`n=== 步骤 3/4  连接仓库并推送 ===" -ForegroundColor Cyan
$defaultRepo = "https://github.com/AMDSE/0712121.xyz"
$repo = Read-Host "  请输入现有 GitHub 仓库 URL (HTTPS 或 SSH，留空则使用 $defaultRepo)"
if (-not $repo) { $repo = $defaultRepo }
Write-Host "  目标仓库：$repo" -ForegroundColor Green

$tmp = Join-Path $env:TEMP ("repo_" + [guid]::NewGuid().ToString("N"))
git clone $repo $tmp
Copy-Item -Path "$PSScriptRoot\*" -Destination $tmp -Recurse -Force
Set-Location $tmp
git add -A
git commit -m "feat: add demo site for Cloudflare Pages"
git push origin HEAD
Write-Host "  ✅ 已推送到 $repo" -ForegroundColor Green

Write-Host "`n=== 步骤 4/4  连接 Cloudflare Pages ===" -ForegroundColor Cyan
Write-Host "  请打开 https://dash.cloudflare.com/?to=/:account/pages 并：" -ForegroundColor Yellow
Write-Host "    1. 创建项目 -> 连接到上面的 Git 仓库" -ForegroundColor White
Write-Host "    2. 构建设置：构建命令 留空，输出目录 填  /" -ForegroundColor White
Write-Host "    3. 保存并部署。之后每次 git push 都会自动部署。" -ForegroundColor White
Write-Host "`n完成！以后改完文件运行 sync.ps1 即可一键推送并触发部署。`n" -ForegroundColor Green
