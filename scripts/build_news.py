"""Render maintained Markdown into static pages: python scripts/build_news.py."""
from pathlib import Path
import json, re, html, zipfile
import markdown

ROOT=Path(__file__).resolve().parents[1]
ARTICLES=json.loads((ROOT/'content/articles.json').read_text(encoding='utf-8'))
e=html.escape
def url(a): return '/news/articles/'+a['id']+'/'
def link(a): return f'<a href="{url(a)}">{e(a["title"])}</a>'
def shell(title,description,body,kind=''):
    return f'''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="description" content="{e(description,quote=True)}"><title>{e(title)} — TOY</title>
<link rel="stylesheet" href="/news/news.css?v=3"><link rel="stylesheet" href="/news/reading.css?v=2">
<script src="/news/orbit.js?v=2" defer></script></head><body class="{kind}">
<a class="skip-link" href="#main">跳到正文</a><header class="masthead"><a class="brand" href="/news/">TOY<span>®</span><small>AIGC NOTES</small></a>
<nav aria-label="主导航"><a href="/news/" aria-current="page">AIGC 观察</a><a href="/news/skills/aigc-shot-workshop/">镜头工坊</a></nav><span class="edition-label">IDEAS · TESTS · PRACTICE</span></header>
{body}<footer class="reading-footer"><a href="/news/">TOY / AIGC 创作笔记</a><a href="#main">回到顶部 ↑</a></footer></body></html>'''

def skill_card():
    return '''<aside class="skill-card"><span class="section-code">配套 SKILL / AIGC 镜头工坊</span><h2>把阅读里的方法，带到下一次创作。</h2><p>给 AI 助手使用的工作指南：拆解镜头、编写提示词、生成关键帧示意图，并按用途检查素材。</p><div class="link-row"><a href="/news/skills/aigc-shot-workshop/">了解镜头工坊 ↗</a><a href="/news/downloads/aigc-shot-workshop.zip" download>下载完整 Skill ↓</a></div></aside>'''

def sidebar(current):
    nodes=''.join(f'<a class="orbit-node" href="{url(a)}" tabindex="-1" aria-hidden="true" title="{e(a["title"])}"><i></i><span>{e(a["label"])}</span></a>' for a in ARTICLES)
    links=''.join(f'<li><a href="{url(a)}" '+('aria-current="page"' if a['id']==current else '')+f'><span>{i+1:02}</span>{e(a["title"])}</a></li>' for i,a in enumerate(ARTICLES))
    return f'''<aside class="reader-sidebar"><details open class="navigation-panel"><summary><span class="summary-title">文章星球</span><span>展开 / 收起</span></summary><div class="navigation-content">
<div class="orbit-block"><div class="orbit" aria-label="球形文章导航"><div class="orbit-ring" aria-hidden="true"></div>{nodes}</div><p class="orbit-hint">拖动或滚动星球，标题靠近时点击阅读。</p><div class="orbit-controls"><button type="button" data-turn="-1" aria-label="向左旋转文章球">←</button><button type="button" data-turn="1" aria-label="向右旋转文章球">→</button></div></div>
<nav aria-label="全部文章"><p class="section-code">READING INDEX · {len(ARTICLES):02} 篇</p><ol class="article-list">{links}</ol></nav><a class="sidebar-skill" href="/news/skills/aigc-shot-workshop/">配套工具：AIGC 镜头工坊 ↗</a></div></details></aside>'''

def write(route,text):
    target=ROOT/route/'index.html';target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text,encoding='utf-8')

for i,a in enumerate(ARTICLES):
    source=(ROOT/'content/articles'/f'{a["id"]}.md').read_text(encoding='utf-8')
    source=re.sub(r'^# .+\n','',source,count=1).lstrip()
    md=markdown.Markdown(extensions=['tables','fenced_code','toc'],extension_configs={'toc':{'permalink':False}})
    rendered=md.convert(source)
    rendered=re.sub(r'<table>(.*?)</table>',r'<div class="table-scroll" role="region" aria-label="文章表格" tabindex="0"><table>\1</table></div>',rendered,flags=re.S)
    figure=''
    if a['id']=='meiren-mv-black-banquet-hall':
        figure='<figure class="article-figure"><img src="/news/media/meiren-banquet.png" alt="《媚人》MV 黑色宴会厅场景：两侧长桌与吊灯，中间通道通向远处台阶"><figcaption>《媚人》MV 场景素材 · 黑色宴会厅</figcaption></figure>'
    prev=link(ARTICLES[i-1]) if i>0 else '<a href="/news/">返回全部文章</a>'
    nxt=link(ARTICLES[i+1]) if i+1<len(ARTICLES) else '<a href="/news/">返回全部文章</a>'
    body=f'''<div class="reader-layout">{sidebar(a['id'])}<main id="main" class="article-main"><a class="back-link" href="/news/">← AIGC 观察</a><header class="article-header"><p class="section-code">{e(a['section'])} / TOY</p><h1>{e(a['title'])}</h1><p class="article-summary">{e(a['summary'])}</p><p class="article-meta">内容更新 <time datetime="{a['updated']}">{a['updated']}</time></p></header>{figure}<details class="contents"><summary>本文目录</summary>{md.toc}</details><div class="prose">{rendered}</div>{skill_card() if a['skill'] else ''}<nav class="article-pagination" aria-label="相邻文章"><div><span>上一篇</span>{prev}</div><div><span>下一篇</span>{nxt}</div></nav></main></div>'''
    write('news/articles/'+a['id'],shell(a['title'],a['summary'],body,'reader'))

featured=ARTICLES[5]
second=ARTICLES[3]
feature=f'''<div class="feature-grid"><a class="feature-story feature-primary" href="{url(featured)}"><p class="section-code">进阶实践 / 镜头设计</p><span class="feature-number">01</span><h3>{e(featured['title'])}</h3><p>{e(featured['summary'])}</p><strong>进入文章 ↗</strong></a><a class="feature-story feature-secondary" href="{url(second)}"><p class="section-code">值得关注 / 提示词</p><span class="feature-number">02</span><h3>{e(second['title'])}</h3><p>{e(second['summary'])}</p><strong>进入文章 ↗</strong></a></div>'''
briefs=[a for a in ARTICLES if a not in (featured,second)]
cards=''.join(f'<article class="story-row"><span class="row-number">{i+1:02}</span><div><p class="section-code">{e(a["section"])}</p><h3>{link(a)}</h3><p>{e(a["summary"])}</p></div><a class="row-arrow" href="{url(a)}" aria-label="阅读：{e(a["title"],quote=True)}">↗</a></article>' for i,a in enumerate(briefs))
archive=''.join(f'<li><span>{e(a["section"])}</span>{link(a)}<time datetime="{a["updated"]}">{a["updated"]}</time></li>' for a in ARTICLES)
body=f'''<main id="main"><div class="eyebrow"><span>TOY'S AIGC FIELD NOTES</span><span>ISSUE 01 / 持续更新</span></div><section class="intro"><div><p class="section-code">从生成结果，回到创作判断</p><h1>AIGC <em>创作笔记<span class="title-dot">.</span></em></h1></div><p class="intro-note">记录真实的尝试、失败与取舍。<br>给新手入口，也给熟练创作者一套可复用的方法。</p></section><div class="issue-bar"><span>VOL. 01</span><span>7 篇文章 · 1 个 Skill</span><span>新手教程 / 方法拆解 / 进阶实践</span><a href="#archive">查看全部 ↘</a></div><section class="focus-section"><div class="section-heading"><h2>重点文章 <span>TOP STORIES</span></h2><span class="section-index">01</span></div>{feature}</section><div class="editorial-grid"><div class="main-column"><section class="brief-section"><div class="section-heading"><h2>快速阅读 <span>IN BRIEF</span></h2><span class="section-index">02</span></div>{cards}</section></div><aside class="side-column"><section class="editor-note"><div class="note-top"><span>创 作 手 记</span><span>TOY</span></div><p class="note-english">FROM FEELING<br>TO FRAME</p><h2 class="note-story-title">为《媚人》搭建一座黑色宴会厅</h2><p>从歌曲带来的感受出发，用黑与红建立空间，再逐步检查画面能不能进入制作。</p><a href="{url(ARTICLES[0])}">阅读制作记录 ↗</a></section><section class="about-column"><p class="section-code">配套工具 / SKILL</p><h2>AIGC 镜头工坊</h2><p>把镜头规划、提示词与素材验收串成一条可以反复使用的工作流程。</p><a href="/news/skills/aigc-shot-workshop/">查看并下载 ↗</a></section></aside></div><section id="archive" class="archive"><div class="section-heading"><h2>全部文章 <span>BACK ISSUES</span></h2><span class="section-index">03</span></div><p class="archive-caption">从基础操作到进阶判断，按内容更新顺序排列。</p><ol class="archive-list">{archive}</ol></section></main>'''
write('news',shell('AIGC 观察','TOY 的 AI 创作教程、镜头实践与素材验收记录。',body))

body=f'''<main id="main" class="skill-page"><a class="back-link" href="/news/">← AIGC 观察</a><p class="section-code">CREATIVE TOOLKIT / SKILL</p><h1>AIGC 镜头工坊</h1><p class="article-summary">把镜头拆解与素材验收，整理成 AI 助手可复用的工作指南。</p><div class="skill-download"><a href="/news/downloads/aigc-shot-workshop.zip" download>下载完整 Skill ↓</a><span>包含主文件、agents 与 references</span></div><div class="prose"><h2>它能做什么？</h2><p>AIGC 镜头工坊是一套给 AI 助手使用的工作指南，将镜头拆解和素材验收串起来。它能按剧情整理分镜、编写提示词，并在支持图像生成的环境中生成对应示意图，再检查构图、素材一致性和待验证问题。</p><p>它不是独立视频生成软件，示意图也不代表动态效果已经通过验证。</p><h2>与这两篇文章一起使用</h2><ul><li>{link(ARTICLES[5])}：把叙事目标整理为镜头方案，按需要细化动作、机位与关键帧。</li><li>{link(ARTICLES[6])}：按用途检查素材，分开记录画面检查、跨镜一致性与动态验证。</li></ul><h2>如何开始</h2><p>解压下载包，保留 aigc-shot-workshop 文件夹及其内部结构，将它添加到支持 Skill 的 AI 助手中。具体加载方式取决于使用环境；仅下载文件不会自动启用图像生成能力。</p><p>准备好要处理的剧情段落或素材，并说明用途、必须保留的内容，以及这次需要镜头设计还是素材检查。</p><h3>镜头规划示例</h3><blockquote>请使用 AIGC 镜头工坊，帮我把这段剧情整理为镜头方案。先讲清每镜要表达什么，再给提示词；缺少的角色或场景参考请明确指出。</blockquote><h3>素材检查示例</h3><blockquote>请使用 AIGC 镜头工坊检查这张图。它将用作视频起始帧，请分别说明已经能判断的问题，以及需要实际视频才能验证的部分。本次只检查，不生成图片。</blockquote><h2>使用时保留这些区别</h2><ul><li>规划中的状态与生成结果中实际看到的状态分开记录。</li><li>新提示词对应新版本，旧图不冒充新生成的示意图。</li><li>静态图、跨镜连续性和动态效果分别验收。</li></ul></div></main>'''
write('news/skills/aigc-shot-workshop',shell('AIGC 镜头工坊','镜头拆解、提示词与素材验收的 AI 助手工作指南。',body))
skill=ROOT/'content/skills/aigc-shot-workshop'
with zipfile.ZipFile(ROOT/'news/downloads/aigc-shot-workshop.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(skill.rglob('*')):
        if p.is_file(): z.write(p,p.relative_to(skill.parent).as_posix())
print('Rendered 7 articles, index, skill page and download package.')
