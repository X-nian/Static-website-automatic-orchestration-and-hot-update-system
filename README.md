# 0712121.xyz · 部署教程与测试页

本仓库是一个**最小可运行的 Cloudflare 部署演示 + 教程**：

- 一个能跑的测试网页（`index.html` + `styles.css`），用来验证部署链路
- 一套完整的 **GitHub → Cloudflare 自动部署**配置（`wrangler.toml`）
- 一个**本地 Git 网页授权脚本**（`git-auth.ps1`），帮你免 token 登录 GitHub 并提交
- 一个**版本存档与切换脚本**（`version.ps1`），把每次改动存成版本并可在版本间切换部署
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

## 二、Git 安装与基础配置

Git 是把代码推送到 GitHub、触发 Cloudflare 自动部署的前提。下面讲清
**在本机安装 Git 并做首次部署前的基础配置**。

### 2.1 下载并安装 Git

1. 打开官网 https://git-scm.com/downloads ，下载 **Windows** 版安装包
   （64-bit Git for Windows Setup）。
2. 双击运行，一路「Next」，关键选项保持默认即可：
   - **Select Components**：勾选 `Git Bash Here`、`Git GUI Here`
   - **Choosing the default editor**：选你习惯的（如 VS Code / Notepad++，
     新手可直接用默认的 Vim 也行）
   - **Adjusting your PATH environment**：选
     **`Git from the command line and also from 3rd-party software`**
     （这样 `git` 命令在 PowerShell / CMD 里都能用，最重要）
   - **Choosing HTTPS transport backend**：选 `Use the native Windows Secure
     Channel library`
   - **Configuring the line ending conversions**：选
     `Checkout Windows-style, commit Unix-style line endings`（默认）
   - **Configuring the terminal emulator**：选 `Use Windows' default console`
   - **Enable Git Credential Manager**：**务必勾选**（它让你 `git push` 时
     弹浏览器登录 GitHub，免去手动管 token）
3. 安装完成后**重启终端**，让 PATH 生效。

### 2.2 验证安装

打开 PowerShell，执行：

```powershell
git --version
```

能输出版本号（如 `git version 2.x.x.windows.1`）即安装成功。

### 2.3 首次使用的基础配置（必做）

Git 提交需要知道你是谁，否则提交会报错。在 PowerShell 里设置全局用户名和邮箱
（用你 GitHub 上的用户名和注册邮箱）：

```powershell
git config --global user.name  "你的GitHub用户名"
git config --global user.email "你的GitHub邮箱"
```

查看已配置：

```powershell
git config --global --list
```

### 2.4 确认凭据助手（网页授权）

安装时勾选的 **Git Credential Manager** 会自动接管认证。确认一下：

```powershell
git config --global credential.helper
# 正常应输出 manager 或 manager-core
```

有了它，之后 `git push` 会**弹出浏览器让你登录 GitHub 并授权**，
登录一次后会记住凭据，后续推送不再重复登录（见第五节）。

### 2.5 准备本地仓库

如果你还没有把本仓库拉到本地，先克隆（需先按第五节解决连 GitHub 的网络问题）：

```powershell
git clone https://github.com/你的用户名/你的仓库.git
cd 你的仓库
```

如果你是用 CodeBuddy 在本仓库里工作，可跳过克隆，直接进入仓库目录操作。

### 2.6 （可选）安装 Node.js 与 Wrangler

实际部署由 **Cloudflare 云端**完成，本机**不需要** Node.js/Wrangler 也能部署。
只有想在本机本地预览时才需要：

1. 装 Node.js：https://nodejs.org （LTS 版），安装后 `node -v` 验证。
2. 装 Wrangler（仅本地调试用）：
   ```powershell
   npm install -g wrangler
   wrangler --version
   ```

---

## 三、仓库里的文件

| 文件 | 作用 |
|------|------|
| `index.html` | 测试网页（你访问站点看到的就是它） |
| `styles.css` | 测试页样式 |
| `wrangler.toml` | Cloudflare 部署配置（**关键**） |
| `git-auth.ps1` | 本地 Git 网页授权登录 GitHub 的脚本 |
| `version.ps1` | 改动自动存档为版本、并切换部署的脚本 |
| `repo-init.ps1` | 本地新建 Git 库并在 GitHub 新建库后唯一绑定 origin 的脚本 |
| `README.md` | 本教程 |

---

## 四、`wrangler.toml` 说明

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

## 五、部署步骤（从零）

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

## 六、本机推送代码的注意事项（实战踩坑）

很多网络环境下 `git push github.com` 会报 `Recv failure: Connection was reset`。
下面三种方式任选其一。

### 方式 A：用脚本一键完成网页授权（推荐）

仓库自带的 `git-auth.ps1` 会自动配置并触发浏览器登录 GitHub：

```powershell
powershell -ExecutionPolicy Bypass -File git-auth.ps1
```

脚本会依次：
1. 设置 Git 凭据助手为 Credential Manager（网页授权方式，push 时弹浏览器）
2. 询问并可选配置代理（解决 `Connection was reset`）
3. 触发一次 GitHub 远程请求 → 弹出浏览器 → 登录并授权

授权完成后即可直接推送（见第七节）。

### 方式 B：手动让 Git 走代理（Clash / V2Ray 等）

```powershell
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
# 端口按你代理软件实际端口改（常见 7890 / 7891 / 1080）
```

配置好代理后，`git push` 会弹出浏览器让你登录 GitHub（Git Credential Manager），
登录完即自动推送，无需手动管理 token。

### 方式 C：改用 SSH 协议

```powershell
ssh-keygen -t ed25519 -C "你的邮箱"        # 生成密钥
# 把 ~/.ssh/id_ed25519.pub 内容加到 GitHub → Settings → SSH keys
git remote set-url origin git@github.com:用户名/仓库.git
git push origin main
```

---

## 七、常见错误排查

| 现象 | 原因 | 解决 |
|------|------|------|
| `Authentication error [code: 10000]` | 部署命令用了 `wrangler pages deploy`，调 Pages API 无权限 | 改用 `npx wrangler deploy` |
| `Missing entry-point to Worker script or to assets directory` | `wrangler.toml` 没 `main` 也没 `[assets]` | 加上 `[assets] directory = "."` |
| 部署成功但页面空白 | 用的是 Worker 项目却没配 `[assets]`，或访问了未绑定的自定义域名 | 配好 `[assets]`，用 `*.workers.dev` 访问 |
| `Connection was reset` | 本机连 GitHub 被重置 | 见第五节（脚本 / 代理 / SSH） |

---

## 八、以后怎么更新内容

改完 `index.html` 等文件后，一条命令即可：

```powershell
git add -A
git commit -m "更新内容"
git push origin main
```

Cloudflare 自动重新部署，无需再登录控制台。

---

## 九、改动自动存档与版本切换（version.ps1）

`version.ps1` 把每次改动存成**带 tag 的版本**（`v1`、`v2` …），并能切换到任意版本部署。

**存档当前改动为新版本**（自动生成下一个版本号）：
```powershell
powershell -ExecutionPolicy Bypass -File version.ps1
# 或带说明：
powershell -ExecutionPolicy Bypass -File version.ps1 save "首页改文案"
```
脚本会 `git add -A` → 提交 → 打 `vN` 标签；最后询问是否 `push` 并带上 tag。

**列出所有版本**：
```powershell
powershell -ExecutionPolicy Bypass -File version.ps1 list
```

**切换到某版本并部署到线上**：
```powershell
powershell -ExecutionPolicy Bypass -File version.ps1 switch v2
```
这会把 `v2` 强制推送到 `main` 分支，触发 Cloudflare 部署该版本（即「切换版本 push」）。

**仅本地查看某版本（不部署）**：
```powershell
powershell -ExecutionPolicy Bypass -File version.ps1 checkout v2
# 查看完返回最新：
git checkout main
```

> ⚠️ `switch` 用的是强制推送（`+vN:main`），会改写线上 `main` 指向的版本。
> 个人/演示项目无妨；团队协作请谨慎。要回到最新版本，再 `switch` 最大的版本号即可。

---

## 十、本地仓库与 GitHub 仓库的新建与绑定（repo-init.ps1）

除了在本仓库里工作，你也可以**从零新建一个项目**：在本地 `git init` 新建仓库，
在 GitHub（网页或用 GitHub CLI）新建对应仓库，然后把二者绑定——**一个本地库
唯一对应一个 GitHub 库（`remote` 名为 `origin`）**。`repo-init.ps1` 把这个流程自动化。

**用法**
```powershell
# 在当前目录操作 (若不是 git 仓库会先 git init)
powershell -ExecutionPolicy Bypass -File repo-init.ps1
# 指定仓库名与可见性:
powershell -ExecutionPolicy Bypass -File repo-init.ps1 -RepoName my-site -Visibility public
```

**脚本会依次做这些事**
1. 进入目标目录；若不是 Git 仓库则 `git init` 新建本地库。
2. 确保已配置 `user.name` / `user.email`（缺失则交互询问）。
3. 处理与 GitHub 的绑定：
   - 若已安装 **GitHub CLI（`gh`）** 且已登录（`gh auth login`），直接
     `gh repo create` 在 GitHub 新建仓库并绑定为 `origin`；
   - 若未安装 `gh`，则提示你去 GitHub 网页新建空仓库，粘贴其 HTTPS URL，
     脚本执行 `git remote add origin <URL>`。
4. **唯一性保证**：若已存在 `origin`，会询问是否先移除旧绑定，确保最终只有
   唯一一个 `origin`（一个本地库 ↔ 一个 GitHub 库）。
5. 可选首次 `commit` 并 `push`。

**手动等价操作（理解原理）**
```powershell
git init                              # 本地新建库
git config user.name  "你的用户名"    # 若未配置
git config user.email "你的邮箱"
# 在 GitHub 网页新建空仓库, 拿到 HTTPS 地址后:
git remote add origin https://github.com/用户名/仓库.git
git add -A
git commit -m "initial commit"
git branch -M main
git push -u origin main
# 查看绑定 (应只有唯一一个 origin):
git remote -v
```

> 提示：本仓库本身已经完成了这套绑定（`origin` →
> `https://github.com/AMDSE/0712121.xyz`）。`repo-init.ps1` 适用于你**新建别的项目**
> 时复用同一套流程。

---

## 十一、绑定自定义域名（可选）

Worker 项目 →「设置」→「触发器」→「自定义域」，添加如 `0712121.xyz`，
按提示去域名 DNS 添加一条 CNAME，指向 `<项目名>.workers.dev`，几分钟生效。
