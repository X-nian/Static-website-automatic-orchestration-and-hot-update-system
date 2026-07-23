<#
  repo-init.ps1 — 在本地新建 Git 仓库, 并在 GitHub 新建仓库后绑定
  核心原则: 一个本地 Git 仓库唯一绑定一个 GitHub 仓库 (origin)
  用法:
    powershell -ExecutionPolicy Bypass -File repo-init.ps1
    powershell -ExecutionPolicy Bypass -File repo-init.ps1 -RepoName my-site -Visibility public
  说明:
    - 若当前目录不是 Git 仓库, 会先 git init
    - 在 GitHub 新建仓库优先用 GitHub CLI (gh); 未安装则改为手动粘贴仓库 URL
    - 若已存在 origin, 会询问是否先移除旧绑定, 确保最终只有唯一一个 origin
    - 首次 commit / push 为可选, 默认不自动推送
#>
param(
    [string]$RepoName = "",
    [ValidateSet("private", "public")][string]$Visibility = "private",
    [string]$Path = "."
)

# 1. 进入目标目录
$dir = Resolve-Path $Path
Set-Location $dir
Write-Host "工作目录: $dir" -ForegroundColor Cyan

# 2. 初始化本地仓库 (若不存在)
if (-not (Test-Path .git)) {
    git init
    Write-Host "✅ 已在本地 git init (新建本地仓库)" -ForegroundColor Green
} else {
    Write-Host "当前目录已是 Git 仓库, 跳过 git init" -ForegroundColor Yellow
}

# 3. 确保提交身份已配置
function EnsureConfig($key, $prompt) {
    $v = git config --get $key
    if (-not $v) {
        $inputVal = Read-Host $prompt
        git config $key $inputVal
    }
}
EnsureConfig "user.name"  "输入 Git 用户名 (用于提交署名)"
EnsureConfig "user.email" "输入 Git 邮箱 (用于提交署名)"

# 4. 处理与 GitHub 的绑定
$existing = git remote get-url origin 2>$null
if ($existing) {
    Write-Host "检测到已绑定的 origin: $existing" -ForegroundColor Yellow
    $ov = Read-Host "是否移除旧 origin 并重新绑定为唯一一个 GitHub 库? (y/N)"
    if ($ov -eq 'y') {
        git remote remove origin
        $existing = ""
    }
}

if (-not $existing) {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if ($gh) {
        # 用 GitHub CLI 在 GitHub 新建仓库并直接绑定为 origin
        if (-not $RepoName) { $RepoName = Split-Path $dir -Leaf }
        $vis = if ($Visibility -eq "public") { "--public" } else { "--private" }

        # 先确认已登录 gh, 未登录则提示登录
        & gh auth status 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "未登录 GitHub CLI, 请先执行: gh auth login (会弹浏览器网页授权)" -ForegroundColor Red
            exit 1
        }

        Write-Host "正在 GitHub 新建仓库 '$RepoName' 并绑定为 origin ..." -ForegroundColor Cyan
        & gh repo create $RepoName $vis --source=. --remote=origin
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 已在 GitHub 新建仓库并绑定为唯一 origin" -ForegroundColor Green
        } else {
            Write-Host "gh 建库失败, 可改用手动方式: 去 GitHub 网页新建仓库后粘贴 URL" -ForegroundColor Red
        }
    } else {
        # 未安装 gh: 改为手动粘贴已建好的 GitHub 仓库 URL
        Write-Host "未检测到 GitHub CLI (gh)。请先到 GitHub 网页新建一个空仓库," -ForegroundColor Cyan
        Write-Host "然后粘贴它的 HTTPS 地址 (形如 https://github.com/用户名/仓库.git):" -ForegroundColor Cyan
        $url = Read-Host "GitHub 仓库 HTTPS URL"
        if ($url) {
            git remote add origin $url
            Write-Host "✅ 已绑定 origin -> $url" -ForegroundColor Green
        } else {
            Write-Host "未提供 URL, 跳过绑定。稍后可手动: git remote add origin <URL>" -ForegroundColor Yellow
        }
    }
}

# 5. 确认唯一绑定关系
Write-Host "=== 当前绑定的远程 (应只有唯一一个 origin) ===" -ForegroundColor Cyan
git remote -v

# 6. 可选的首次提交与推送
$ans = Read-Host "是否做首次 commit 并 push 到 GitHub? (y/N)"
if ($ans -eq 'y') {
    git add -A
    git commit -m "initial commit"
    git branch -M main
    git push -u origin main
    Write-Host "✅ 已首次推送到 GitHub" -ForegroundColor Green
} else {
    Write-Host "已跳过推送。需要时手动: git add -A; git commit -m '...'; git push -u origin main" -ForegroundColor Yellow
}

Write-Host "完成: 一个本地库已唯一绑定一个 GitHub 库 (origin)。" -ForegroundColor Green
