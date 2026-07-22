# 0712121.xyz · 部署教程与测试页

本仓库是一个**最小可运行的 Cloudflare 部署演示 + 教程**：

- 一个能跑的测试网页（`index.html` + `styles.css`），用来验证部署链路
- 一套完整的 **GitHub → Cloudflare 自动部署**配置（`wrangler.toml`）
- 本文档：从零讲清部署过程、所需软件、所需代码、以及实战踩过的坑

---

## 一、需要的软件

| 软件 | 用途 |
|------|------|
| **Git** | 把代码推送到 GitHub，触发自动部署 |
| **GitHub 账号** | 托管代码仓库 |
| **Cloudflare 账号** | 创建 Worker 项目并托管站点 |
| （可选）**代理 / VPN 或 SSH** | 解决本机 `git push` 连 GitHub 被重置的问题 |
| （可选）**Node.js + Wrangler** | 仅本地调试用；实际部署由 Cloudflare 云端完成 |

> 本项目是**纯静态站点**，不需要 `npm install` / 构建步骤。

---

## 二、仓库里的文件

| 文件 | 作用 |
|------|------|
| `index.html` | 测试网页（你访问站点看到的就是它） |
| `styles.css` | 测试页样式 |
| `wrangler.toml` | Cloudflare 部署配置（**关键**） |
| `README.md` | 本教程 |

---

## 三、`wrangler.toml` 说明

```toml
name = "blog"
compatibility_date = "2026-07-21"

# 把仓库根目录作为静态资源直接托管
# 访问站点时即显示 index.html
[assets]
directory = "."
```

`[assets] directory = "."` 是核心：它告诉 Cloudflare 把当前目录的静态文件
（主要是 `index.html`）发布成站点，无需任何 Worker 脚本入口。

---

## 四、部署步骤（从零）

1. **在 Cloudflare 创建 Worker 项目并连接 GitHub**
   - 登录 https://dash.cloudflare.com → 「Workers 和 Pages」→「创建」→「连接到 Git」
   - 授权 GitHub，选择本仓库

2. **构建设置（关键，填错必失败）**
   - **部署命令**：`npx wrangler deploy`
   - **构建命令**：留空（或填 `echo ok`）
   - ⚠️ **不要**填 `wrangler pages deploy` —— 它会去调 Pages API，云端 token 无权限，报 `10000`

3. **确保仓库根目录有 `wrangler.toml`**（含上面的 `[assets]` 配置）

4. **推送代码**，Cloudflare 检测到 push 会自动构建并部署

5. **访问** `https://<项目名>.<子域>.workers.dev`（如 `blog.tmr3187435155.workers.dev`）

---

## 五、本机推送代码的注意事项（实战踩坑）

很多网络环境下 `git push github.com` 会报 `Recv failure: Connection was reset`。
两种解决办法：

**方案 A：让 Git 走代理（Clash / V2Ray 等）**

```powershell
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
# 端口按你代理软件实际端口改（常见 7890 / 7891 / 1080）
git push origin main
```

**方案 B：改用 SSH 协议**

```powershell
ssh-keygen -t ed25519 -C "你的邮箱"        # 生成密钥
# 把 ~/.ssh/id_ed25519.pub 内容加到 GitHub → Settings → SSH keys
git remote set-url origin git@github.com:用户名/仓库.git
git push origin main
```

> 配置好代理后，`git push` 会弹出浏览器让你登录 GitHub（Git Credential Manager），
> 登录完即自动推送，无需手动管理 token。

---

## 六、常见错误排查

| 现象 | 原因 | 解决 |
|------|------|------|
| `Authentication error [code: 10000]` | 部署命令用了 `wrangler pages deploy`，调 Pages API 无权限 | 改用 `npx wrangler deploy` |
| `Missing entry-point to Worker script or to assets directory` | `wrangler.toml` 没 `main` 也没 `[assets]` | 加上 `[assets] directory = "."` |
| 部署成功但页面空白 | 用的是 Worker 项目却没配 `[assets]`，或访问了未绑定的自定义域名 | 配好 `[assets]`，用 `*.workers.dev` 访问 |
| `Connection was reset` | 本机连 GitHub 被重置 | 见第五节（代理 / SSH） |

---

## 七、以后怎么更新内容

改完 `index.html` 等文件后，一条命令即可：

```powershell
git add -A
git commit -m "更新内容"
git push origin main
```

Cloudflare 自动重新部署，无需再登录控制台。

---

## 八、绑定自定义域名（可选）

Worker 项目 →「设置」→「触发器」→「自定义域」，添加如 `0712121.xyz`，
按提示去域名 DNS 添加一条 CNAME，指向 `<项目名>.workers.dev`，几分钟生效。
