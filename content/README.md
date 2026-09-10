# AIGC 观察内容维护

网站正文由本目录的 Markdown 和 articles.json 生成，浏览器不需要运行 Python。

1. 编辑 articles/ 中的正文，不加入编辑交接信息或草稿备注。
2. 在 articles.json 中维护标题、摘要、分类与真实内容更新日期。id 是永久链接的一部分，更新文章时保留 id。
3. 新文章添加独立 Markdown 文件和一条 articles.json 记录。列表顺序就是推荐阅读顺序。
4. 安装生成依赖：`python -m pip install -r scripts/requirements.txt`。
5. 在仓库根目录执行 `python scripts/build_news.py`，生成文章、首页、目录和技能页。
6. 将内容源和生成结果一起提交，沿用现有 Cloudflare 静态发布流程。

技能源位于 skills/aigc-shot-workshop/。更新这个目录后再次执行生成命令，下载包随之更新。两篇关联文章通过 articles.json 的 skill 字段展示卡片。

来源版本：网站实装交接于 2026-09-10 指定的七篇完整稿。模拟声明保留在正文中；宴会厅教程为用户确认的完整扩写稿，练习提示词不是当时原始提示词。

预览：`python -m http.server 8766 --bind 127.0.0.1`，访问 `/news/`。页面使用站点根路径链接，请通过 HTTP 服务预览。
