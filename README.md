# 演示站点（Cloudflare Pages）

这是一个用于验证「GitHub → Cloudflare Pages」实时部署链路的静态演示站点。

## 目录结构
- `index.html` — 主页
- `styles.css` — 样式

## 本地预览
直接用浏览器打开 `index.html` 即可，无需构建步骤。

## 部署方式
1. 将本仓库连接到 GitHub。
2. 在 Cloudflare 控制台 → Pages → 创建项目 → 连接 Git 仓库。
3. 构建设置：
   - 构建命令：留空（纯静态）
   - 构建输出目录：`/`（仓库根目录）
4. 每次 `git push` 即自动部署。

## 常用命令
```bash
git add .
git commit -m "update site"
git push
```
