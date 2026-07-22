<#
  version.ps1 — 改动自动存档为版本, 并可在版本间切换部署
  用法:
    powershell -ExecutionPolicy Bypass -File version.ps1                 # 存档当前改动为新版本 (v1, v2 ...)
    powershell -ExecutionPolicy Bypass -File version.ps1 save "版本说明"  # 带说明存档
    powershell -ExecutionPolicy Bypass -File version.ps1 list            # 列出所有版本
    powershell -ExecutionPolicy Bypass -File version.ps1 switch v2       # 切换并部署版本 v2
    powershell -ExecutionPolicy Bypass -File version.ps1 checkout v2     # 仅本地切到 v2 查看 (看完 git checkout main 返回)
#>
param(
    [string]$Action = "save",
    [string]$Arg = ""
)

function NextVersion {
    $nums = git tag --list "v*" | ForEach-Object {
        if ($_ -match '^v(\d+)$') { [int]$Matches[1] }
    } | Sort-Object -Descending
    if ($nums) { return "v$($nums[0] + 1)" } else { return "v1" }
}

switch ($Action) {
    "save" {
        $ver = NextVersion
        $msg = if ($Arg) { $Arg } else { "版本 $ver 自动存档" }
        git add -A
        git diff --cached --quiet
        if ($LASTEXITCODE -eq 0) {
            Write-Host "没有需要存档的改动。" -ForegroundColor Yellow
            exit 0
        }
        git commit -m "$msg"
        git tag -a $ver -m $msg
        Write-Host "✅ 已存档为版本 $ver" -ForegroundColor Green
        $ans = Read-Host "是否推送到 GitHub 并部署? (y/N)"
        if ($ans -eq 'y') { git push origin main --tags }
    }
    "list" {
        Write-Host "=== 已有版本 ===" -ForegroundColor Cyan
        git tag --list --sort=-creatordate
    }
    "switch" {
        if (-not $Arg) { Write-Error "请指定版本, 例如: version.ps1 switch v2"; exit 1 }
        $ver = $Arg
        $null = git rev-parse "$ver^{commit}" 2>$null
        if ($LASTEXITCODE -ne 0) { Write-Error "版本 $ver 不存在"; exit 1 }
        Write-Host "将把版本 $ver 推送到 main 并触发部署..." -ForegroundColor Yellow
        git push origin "+$ver:main"
        Write-Host "✅ 已部署版本 $ver 到线上" -ForegroundColor Green
    }
    "checkout" {
        if (-not $Arg) { Write-Error "请指定版本, 例如: version.ps1 checkout v2"; exit 1 }
        git checkout $Arg
        Write-Host "已切换到 $Arg (detached HEAD), 查看完用 'git checkout main' 返回。" -ForegroundColor Green
    }
    default {
        Write-Host "未知操作: $Action" -ForegroundColor Red
        Write-Host "用法: version.ps1 [save|list|switch|checkout] [参数]"
    }
}
