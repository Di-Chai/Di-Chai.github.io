# Di Chai — academic homepage

白底、柔和蓝色、紧凑单栏的学术主页。根目录 `index.html` 是已经生成好的完整静态网页，**可以直接双击，用浏览器打开**。图片和样式使用相对路径，离线也能正常显示。

页内跳转、Research insight 和 All publications 的展开在关闭 JavaScript 时也可使用。少量本地 JavaScript 为吸顶导航补充当前位置标识和动态定位间距。页面运行不依赖 Jekyll、Bundler、本地服务器或远程字体。

## 查看与更新主页

1. 在浏览器中打开根目录 `index.html`（保留旁边的 `assets/` 文件夹）。
2. 修改 `_data/publications.yml` 中的论文或研究亮点，修改 `_data/profile.yml` 中的个人信息，或在 `_data/students.yml` 补充招生介绍。
3. 双击 **`更新主页.command`**，会重新生成 `index.html` 并用默认浏览器打开。

也可以在项目目录运行：

```sh
ruby scripts/build.rb
```

生成器仅使用 Ruby 标准库，兼容这台 Mac 自带的 Ruby 2.6，无需安装 gem。**不要直接修改生成的 `index.html`**，再次生成时会覆盖它。

发布前检查内容是否已经生成到网页：

```sh
ruby scripts/build.rb --check
```

如果 YAML 格式有误，生成器会提示错误并保留上一份网页。

## 更新内容

日常更新只需编辑文本内容文件。目前使用 YAML（`.yml`），可以像 Markdown 一样在文本编辑器中修改；它按“字段名: 内容”组织数据，适合论文这种固定格式的列表。

**论文列表和 Highlighted Projects 都在 `_data/publications.yml` 维护**：每条记录是论文信息，其下的 `highlight` 是可选的研究亮点。论文链接和代码链接只需填写一次，两个区域会共用。

| 文件 | 内容 |
| --- | --- |
| `_data/profile.yml` | 个人简介、联系方式、SUFE 教师页链接与招生提示 |
| `_data/students.yml` | To Prospective Students 的介绍、研究方向与 proposal 链接 |
| `_data/publications.yml` | 全部论文、作者、会议、论文/代码链接，以及 `highlight` 研究亮点 |
| `_templates/home.html.erb` | 页面结构、个人介绍、搜索与分享元数据 |
| `_templates/highlight.html.erb` | Highlighted Projects 的紧凑条目 |
| `_templates/publication.html.erb` | 论文条目 |
| `_templates/students.html.erb` | 学生介绍区域 |
| `assets/css/main.css` | 页面样式、字号和手机布局 |
| `assets/js/navigation.js` | 页内目录当前位置、吸顶高度适配 |
| `assets/js/image-viewer.js` | 项目配图的页内放大、关闭与焦点恢复 |
| `_config.yml` | 网站标题、描述、正式网址和 GitHub Pages 排除项 |
| `scripts/build.rb` | 从内容文件与模板生成静态网页 |

### 新增论文

向 `_data/publications.yml` 添加一条记录。`id` 必须唯一，使用小写字母、数字与短横线；`authors` 保留论文的原始署名顺序。
页面按年份倒序显示，同一年内沿用数据文件的顺序。`selected: true` 的论文默认展示；设为 `false` 或省略时，在 All publications 内展开。如果没有选择任何精选论文，页面直接展示完整列表。

```yaml
- id: project-id
  title: Paper title
  authors: [Di Chai, Another Author]
  year: 2026
  venue: Conference 2026
  selected: true
  paper: https://example.com/paper
  code: https://github.com/example/project
```

没有论文正文链接时可省略 `paper`，页面会显示纯文字标题，并隐藏 Paper 链接；之后补上即可。没有开源链接时省略 `code`。可选的 `video` 字段填写教程视频地址，会在论文条目和 Highlighted Projects 中显示 Tutorial video 链接。

### 更新 Highlighted Projects

在 `_data/publications.yml` 中找到对应论文，修改它的 `highlight` 即可。给其他论文添加 `highlight`，就会展示新的研究亮点。
建议保留 1–3 项重点成果；旧成果移除整个 `highlight` 段即可，论文记录仍然保留。`selected` 与 `highlight` 分别控制两个区域，互不依赖。
研究亮点同样按年份倒序、同年按数据文件顺序显示；当前 KVMem 在 Centrifuge 前面。

```yaml
- id: project-id
  title: Paper title
  authors: [Di Chai, Another Author]
  year: 2026
  venue: Conference 2026
  selected: true
  paper: https://example.com/paper
  code: https://github.com/example/project
  video: https://www.bilibili.com/video/BV1r2ey6EEh5/
  highlight:
    name: Project name
    summary: One sentence explaining the research contribution.
    insight: A longer explanation shown when Research insight is expanded.
```

`name` 和 `summary` 必填；`insight` 可选。`result`、`result_label`、`conditions` 可用于补充带实验条件的数值结果，放在折叠的详情中；填写结果时需同时填写后两项。如添加 `proceedings` 字段，详情会链接到会议论文页。

项目配图也在对应的 `highlight` 下维护，图片放入 `assets/img/`。点击缩略图可在当前页面放大，再次点击大图、背景、右上角关闭按钮或按 Esc 即可关闭，并回到原来的阅读位置。关闭 JavaScript 或浏览器不支持弹窗时，保留直接打开图片的链接；可选的 `caption` 是图注，`source` 链接到图片来源。当前 KVMem 和 Centrifuge 使用提供的项目宣传图，按原始比例完整显示。

```yaml
    image:
      path: assets/img/centrifuge-project.png
      alt: Centrifuge project illustration showing tokens passing through a filtering device.
```

`path` 和 `alt` 必填；生成时会检查图片文件是否存在。不需要配图时移除整个 `image` 段，即恢复纯文字条目。

新版已将动态合并到 Highlighted Projects。旧版 `_data/news.yml` 与 `highlight` 中的 `tagline`、`topic`、`illustration` 作为原始数据保留，当前页面不读取它们。研究方向在简介中说明，旧版 `profile.interests` 列表也不单独展示。

### 更新 To Prospective Students

编辑 `_data/students.yml`。`intro` 写招生理念和联系说明，空行分段，支持 `**加粗**`，个人邮箱自动显示为邮件链接；`directions` 列出研究方向，`proposals` 放详细计划或 PDF 链接。入口在 Recruiting students 下一行，与招生提示共用上下两条横线；默认收起，点击标题展开，再次点击收起。研究方向和 proposal 列表暂为空，可后续补充。

```yaml
title: To Prospective Students
intro: |
  在这里介绍你的研究理念、招生方向和对学生的期待。

  可以继续写第二段。
directions:
  - title: 研究方向名称
    summary: 说明研究问题与切入点。
proposals:
  - title: Proposal 标题
    description: 简述计划要解决的问题。
    url: https://example.com/proposal
```

本地 PDF 放在 `assets/pdf/`，`url` 填写 `assets/pdf/实际文件名.pdf`。生成时会检查本地文件是否存在。暂时没有条目时保留 `directions: []` 或 `proposals: []`，对应列表不显示。

顶部是左对齐的页内目录：**About / Hiring / Projects / Publications**，点击会定位到对应区域。Hiring 指向简介下方的招生说明。滚动时当前栏目自动标蓝；手机上导航会换行，定位会避开吸顶栏。Projects 指向 Highlighted Projects。没有研究亮点时会自动隐藏 Projects 导航。招生内容仍在简介下方展开。

右上角是单个颜色切换按钮：浅色显示太阳，深色显示月亮，点击切换到另一种模式。首次访问默认跟随 macOS 等操作系统的颜色偏好并实时响应变化；手动切换后会记住当前浏览器的选择。主题逻辑在 `assets/js/theme.js`，配色变量在 `assets/css/main.css`，打印始终使用浅色。

### 编辑注意事项

- 保留空格缩进，不使用 Tab；年份写成数字，如 `2026`。
- 标题含冒号等符号时用引号包住。
- 示例中的 `project-id` 和链接需替换成实际内容，不要作为真实成果发布。
- 个人简介的 `biography`、`collaborations` 支持自己编写的简单 HTML（如链接与加粗）；论文与亮点字段按普通文字显示。
- 保存内容后运行一次生成；浏览器不会直接读取 YAML。对话里的旧示意稿也不会自动更新，以根目录 `index.html` 为准。

## GitHub 自动构建与发布

仓库：`Di-Chai/Di-Chai.github.io`。自动流程在 `.github/workflows/pages.yml`，推送到 `master` 时运行：

1. 使用 Ruby 3.3 读取 `_data/` 与 `_templates/`，重新生成主页。
2. 将生成的 `index.html` 与 `assets/` 打包为静态网站。
3. 通过 GitHub Pages 发布到 `https://di-chai.github.io/`。

PR 会构建检查，但不会发布。也可以在 Actions 页面选择 **Build and deploy homepage → Run workflow**，从 `master` 手动触发。

### 首次启用

1. 将本项目文件（包括 `.github/workflows/pages.yml`）提交并推送到 GitHub。
2. 在仓库 **Settings → Pages → Build and deployment → Source** 选择 **GitHub Actions**。
3. 在 **Actions** 中运行或重新运行 **Build and deploy homepage**。首次部署成功后查看主页。

以后可以直接在 GitHub 网页编辑 `_data/publications.yml` 、`_data/profile.yml` 或 `_data/students.yml`，提交到 `master` 后自动更新网站；**不需要在本地生成或手动上传 `index.html`**。构建失败时不会进入部署步骤，可在 Actions 中查看错误。

本地双击预览仍使用根目录 `index.html`，修改 YAML 后要双击 `更新主页.command`。Actions 只生成部署产物，不把生成的 HTML 回写仓库，因此拉取远端内容更新后，本地也要重新生成一次。

部署产物仅包含网页与 `assets/`，不包含数据源、模板、README 或本地脚本。该自动流程不安装 Jekyll 或 Bundler，也不需要额外设置个人访问令牌。Gemfile 与原有 Jekyll 配置保留用于兼容旧的分支发布方式；启用新工作流时应按上面说明切换 Pages Source。

`_config.yml` 的 `url` 与 `baseurl` 用于生成 canonical 和分享链接。手动发布到其他静态空间时，先本地生成，再上传 `index.html` 和 `assets/` 即可。原有 PDF 与头像地址保留。CV 与研究陈述尚未更新，因此没有增加新的首页入口。
