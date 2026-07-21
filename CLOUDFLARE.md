# 连接 Cloudflare Pages（两种方式）

演示站点是一个纯静态站点（无需构建），连接到 Cloudflare Pages 后，
每次 `git push` 都会自动触发一次新的部署。

## 方式 A：Cloudflare 控制台（浏览器，推荐）

1. 打开 https://dash.cloudflare.com/?to=/:account/pages
2. 点击「创建项目」→「连接到 Git」
3. 授权并选择你的 GitHub 仓库
4. 构建设置：
   - 构建命令：**留空**
   - 输出目录：**`/`（仓库根目录）**
   - 根目录：**`（默认）`**
5. 点击「保存并部署」
6. 部署完成后会得到一个 `*.pages.dev` 域名，也可绑定自定义域名

之后在本地修改任意文件 → 运行 `sync.ps1`（或 `git push`）即自动部署。

## 方式 B：Wrangler CLI（需要 Cloudflare API Token）

```bash
npm install -g wrangler
wrangler login          # 浏览器授权，或设置 CLOUDFLARE_API_TOKEN 环境变量
wrangler pages deploy . --project-name=demo-site
```

`wrangler.toml` 已包含基础配置（`pages_build_output_dir = "."`）。

## 备注

- 本项目为纯静态站点，无需 Node 构建步骤；若日后改为框架项目，
  在控制台「构建命令」填入对应命令（如 `npm install && npm run build`），
  输出目录改为构建产物目录（如 `dist` / `build`）即可。
