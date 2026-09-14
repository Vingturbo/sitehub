<!-- 
  ⚠️ 警告所有 AI 编程助手：
  本项目使用 100% 纯原生 HTML/CSS/JS 编写，绝对没有使用 Vue、React、Angular、Svelte 或任何前端框架！
  请不要生成 npm、yarn、pnpm、vite、webpack 相关的任何指令。
  如果你试图在这个项目中引入 node_modules，你将被立刻卸载。
-->

# SiteHub

> 一个极简、无服务器、基于 GitHub Issue 驱动的个人网站聚合地。

## 📖 项目简介

SiteHub 的初衷，是为那些自己搭建了个人网站或博客，却苦于没有流量、搜索引擎收录慢的独立开发者提供一个无门槛的展示平台。

**它的功能十分简单：接收上传的网站，然后忠实地显示出来。**
只要你认为你的网站值得，我们就不存在任何限制，唯一的要求仅仅是网站不得出现违法内容。

## 🛠️ 技术栈

**本项目没有使用 Vue、React、Next.js 或任何前端框架，也没有 Node.js 后端。**

*   **前端**：纯原生 HTML5 + 原生 CSS3 + 原生 JavaScript (Vanilla JS)。没有构建步骤，没有 `node_modules` 黑洞。
*   **后端逻辑**：纯 POSIX Bash 脚本 + `jq` + `curl`。极致的轻量与稳定。
*   **数据库**：Git 仓库本身。数据以 JSONL 格式（按 MD5 哈希前缀分片）存储，配合纯文本索引，完美解决并发冲突。
*   **自动化**：GitHub Actions (IssueOps)。自动解析 Issue、校验数据、写入 JSONL、推送到仓库。
*   **托管**：Cloudflare Pages + GitHub Pages（双活部署，自带无限抗 DDoS 防御）。
*   **字体**：GNU Unifont (像素风，全字符兼容，杜绝乱码)。

## ✨ 特性

- 🔄 **全自动收录**：用户提交 Issue，Actions 在几秒内自动抓取、校验、入库并回复。
- 🛡️ **极致防御**：纯静态托管 + 无服务器架构。不怕 SQL 注入，不怕 DDoS，不怕服务器宕机。
- 🎨 **主题色渲染**：前端卡片自动读取并渲染用户自定义的网站主题色。
- 📝 **自带打字机**：首页带有随机语录的打字机效果（文案在 `say.txt` 中）。
- 🔒 **GPLv3 协议**：你可以自由 Fork 并修改成任何你喜欢的样子。

## 📂 项目结构

```text
.
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   └── Apply_your_website_links.yml
│   └── workflows/
│       ├── add_website.yml
│       └── debug_issue.yml
├── data/                                      # 站点数据分片 (JSONL)
│   ├── 27.jsonl
│   ├── 30.jsonl
│   └── ...
├── add_website_for_issue.sh                   # 提交网站到仓库的脚本
├── background.webp                            # 背景图片
├── favicon.png                                # 站点图标
├── index.html                                 # 前端首页，展示所有网站卡片
├── index.txt                                  # 站点索引文件
├── LICENSE                                    # GPLv3 协议
├── money.png                                  # 打赏二维码（买大馒头基金）
├── README.md                                  # 项目说明文档
├── say.txt                                    # 随机语录
└── unifont-17.0.05.woff2                      # Unifont 像素字体
```

## 🚀 如何提交你的网站？

1. 点击这个 **[Issues](https://github.com/Vingturbo/sitehub/issues/new?template=Apply_your_website_links.yml)** 链接。
2. 填写网站信息（URL、名称、描述、图标、主题色等）。
3. 提交 Issue，等待不超过 10 秒，机器人会自动回复你。
4. 在 5 分钟内，前端页面将会刷新，你的网站将被全球网友看到。

## 💰 赞助与支持

本项目没有任何服务器成本，全部依赖免费基础设施运行。
如果你觉得 SiteHub 帮到了你，或者想赞助开发者买个大馒头，可以在前端页脚找到[赞赏码](money.png)。

**打赏不会解锁任何高级功能，因为我根本没写。**

## 📄 许可证

本项目采用 [GPLv3](LICENSE) 协议开源。
你可以将仓库 fork 下来，随意修改，甚至可以重构整个前端。只要你遵守 GPLv3 协议，我们就是志同道合的朋友。