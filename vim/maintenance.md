# Vim 维护记录

> 面包屑：[dotfiles](../CLAUDE.md) > [vim](CLAUDE.md) > 维护记录

本文件记录 Vim 工具链的**版本状态**、**回归测试命令**、**更新/恢复步骤**与后续实施待办。
配置说明见 [vim/CLAUDE.md](CLAUDE.md)，日常操作见 [实用手册](practical-guide.md)。

## 版本状态

版本分两类，含义不同，不要混用：

- **已固定（pinned）**：由仓库内配置显式锁定，换机器重建会得到同一版本。改动需要走评估流程。
- **当前观测（observed）**：本机实测值，不由本仓库锁定。系统更新、Homebrew 升级或 TeX 发行版更新都可能改变，仅作为"本轮测试在什么环境下通过"的记录。

### 已固定

| 组件 | 固定版本 | 固定位置 |
|------|----------|----------|
| VimTeX | `v2.15`（`9f6a5bb0a9c9f1542fe88dc07511ce8401242e2a`） | [`.vimrc`](.vimrc) 的 `Plug 'lervag/vimtex', {'tag': 'v2.15'}` |
| LanguageServer.jl | 4.5.1（Julia 1.12.7） | [`.vim/julia-language-server/`](.vim/julia-language-server/) 的 `Project.toml` / `Manifest.toml` |

### 当前观测（2026-09-08 本轮实测）

| 组件 | 观测版本 | 获取命令 |
|------|----------|----------|
| Vim | 9.2（Vim 发布日期 2026 Feb 14，`+clientserver` `+job` `+channel`） | `vim --version \| head -1` |
| latexmk | 4.88 | `latexmk --version` |
| pdfTeX | 3.141592653-2.6-1.40.29（TeX Live 2026） | `pdflatex --version \| head -1` |
| texlab | 5.26.0（Homebrew） | `texlab --version` |
| Skim | 1.7.9 | `defaults read /Applications/Skim.app/Contents/Info.plist CFBundleShortVersionString` |
| coc-pyright | 1.1.413；登记范围 `>=1.1.413`，并非精确固定 | CoC 扩展登记及安装包版本 |
| Node.js | v26.8.1 | `node --version` |
| 插件总数 | 17 | `ls ~/.vim/plugged \| wc -l` |

Vim 9.2 高于 [vim/CLAUDE.md](CLAUDE.md) 记录的 CoC 最低要求 9.0.0438。

## 回归测试

[`tests/run-latex-build-tests.sh`](tests/run-latex-build-tests.sh) 覆盖 VimTeX 构建包装器
（[`.vim/latex-build.vim`](.vim/latex-build.vim)）的稳定性。**可从任意工作目录运行**，
自身解析仓库位置，不硬编码用户名或 home 绝对路径。

```bash
# 任意 cwd
<repo>/vim/tests/run-latex-build-tests.sh

# 保留临时工作区与 Vim 会话日志用于排查
<repo>/vim/tests/run-latex-build-tests.sh --keep

# 指定工作区目录 / 调整整体超时（默认 420 秒）
<repo>/vim/tests/run-latex-build-tests.sh --workspace /tmp/my-run --timeout 600
```

退出码：`0` 全部通过；`1` 存在失败用例；`2` 依赖缺失或测试自身错误。

### 覆盖范围

| 用例组 | 验证内容 |
|--------|----------|
| `preflight/*` | 包装器与命令加载、VimTeX 固定版本、单次构建、**不自动弹出 PDF**、`+clientserver` |
| `mapping/*` | `Space lb` / `lv` / `ls` / `lo` 四个映射指向正确命令 |
| `root/*` | 含空格路径下，从子文件经 `% !TeX root` 识别主文件 |
| `build/*` | 子文件触发构建成功；`.latexmkrc` 的 `$out_dir` 生效（PDF/日志进入 `build output`，源码旁无残留 PDF） |
| `error/*` | 真实 LaTeX 错误进入 quickfix，且定位到**正确子文件的正确行号** |
| `fix/*` | 修复后重建 quickfix 清空、PDF 时间戳更新 |
| `guard/*` | 其他未保存 TeX buffer 阻止构建；无主文件时明确拒绝 |
| `repeat/*` | 构建进行中重复触发被拒绝，原构建不受影响 |
| `stop/*` | `VimtexStop` 真正终止运行中的构建 |
| `packaging/*` | `bootstrap.sh` 不应把仓库侧测试资产链接进 `$HOME` |

### 设计约定

- **不引入测试框架**：只有 Bash + Vim script，结果以 TSV 传递。
- **不编译真实科研项目**：每次运行在临时工作区现造最小论文样例（含空格路径、多文件、自定义 `$out_dir`）。
- **不干扰用户窗口**：断言 `g:vimtex_view_automatic == 0`，且从不调用 `VimtexView`；`Space lv` 只检查映射，不打开 Skim。
- **不跳过必要检查**：缺少 `vim` / `latexmk` / `pdflatex` / `+clientserver` / VimTeX 时以退出码 `2` 明确失败，绝不静默跳过后宣称通过。
- **超时即失败**：每次构建等待上限 120 秒，整体会话上限 420 秒，超时记为 `FAIL` 或杀掉会话。
- 测试以 `-u <repo>/vim/.vimrc` 加载真实配置，并追加 `--cmd 'set nocompatible'`
  （`-u` 指定文件时 Vim 不会自动关闭 `compatible`，否则插件行为异常）与
  `--cmd 'let g:coc_start_at_startup = 0'`（本套件不涉及语言服务）。

### 本轮结果（2026-09-08）

39 项通过，1 项失败：`packaging/test-assets-not-linked`。详见下节"已知问题"。
已用反向对照验证套件非空转：移除样例 `.latexmkrc` 的 `$out_dir` 后，
三项 `build/*` 断言如期转为 `FAIL`。

## 已知问题

### bootstrap 安装范围（已修复并验证）

现有排除规则跳过包顶层 Markdown 文档和测试目录，保留嵌套插件文档与实际配置。
新增独立回归入口：`bash scripts/tests/bootstrap-tests.sh`。

2026-09-11 临时合成仓库验证通过：macOS/Linux 筛选、配置链接、文档与测试排除、
原文件备份、重复运行、dry-run 无写入，以及上级目录已链接时的源文件保护。
测试还复现了仓库路径经过符号链接时保护漏判的问题；bootstrap 的脚本目录与仓库根目录
改用 `pwd -P`，通过符号链接入口运行的回归已通过。未向真实 Home 安装或清理旧链接。

### GUI 未验收项

Skim 的鼠标点击、PDF 高亮位置与窗口前台焦点**仍未完成视觉验收**，与第六轮记录一致。
本轮没有可用的 GUI 检查工具，且不使用 AppleScript / osascript / System Events
等方式操纵界面，因此仅登记为待人工验收项：

1. Skim 中 **Shift + Command** 点击 PDF 文字，确认跳回正确的源文件与行。
2. 确认 PDF 中高亮位置与源码位置一致。
3. 确认 `Space lv` 后 Skim 窗口的前台焦点行为符合预期。

命令层面的回调此前已验证可定位到正确文件与行号；**命令成功不等于 GUI 验收**。

## 更新与恢复

### 更新 VimTeX

1. 阅读目标版本的 release notes 与 `doc/vimtex.txt` 变更。
2. 修改 [`.vimrc`](.vimrc) 中的 `{'tag': 'vX.Y'}`，运行 `:PlugUpdate vimtex`。
3. 运行回归套件：`<repo>/vim/tests/run-latex-build-tests.sh`。
   套件内 `VIMTEX_PIN` 也要同步改为新 tag，否则 `preflight/vimtex-pinned-version` 会失败。
4. 补做上面的 GUI 人工验收项。
5. 通过后更新本文件的"已固定"表与 [vim/CLAUDE.md](CLAUDE.md)。

### 恢复 VimTeX 到 v2.15

```bash
cd ~/.vim/plugged/vimtex
git checkout 9f6a5bb0a9c9f1542fe88dc07511ce8401242e2a
```

并确认 [`.vimrc`](.vimrc) 中为 `{'tag': 'v2.15'}`，然后重跑回归套件。

### 恢复本轮配置改动

本轮**未修改任何实现文件**。`.vimrc`、`.vim/latex-build.vim`、CoC 配置与 Skim 偏好均为只读。
若只需撤销本轮新增的测试与文档：

先检查当前差异并保存本轮新增文件的副本，只撤销本轮新增的测试、维护文档及手册末尾入口。若这些文件已有后续修改，保留后续内容；不要整文件 checkout 或递归删除目录。

### 恢复 Skim 反向搜索设置

仅恢复三项，不要整体导入旧偏好（会覆盖后续设置）：
`SKTeXEditorPreset`、`SKTeXEditorCommand`、`SKTeXEditorArguments`。
当前值对应 Custom 编辑器，Arguments 为
`-v --not-a-term -T dumb -c "VimtexInverseSearch %line '%file'"`，
Command 为 `command -v vim` 的结果。原先无显式值时应删除这三个覆盖项。

### 依赖缺失时的排查

套件以退出码 `2` 报告依赖问题。常见原因：

- `vim` / `latexmk` / `pdflatex` 不在 `PATH`（TeX 通常在 `/Library/TeX/texbin`）。
- Vim 缺少 `+clientserver`：反向搜索所需，需换用 Homebrew Vim。
- `~/.vim/plugged/vimtex` 不存在：在 Vim 中运行 `:PlugInstall`。

复核修正：`--workspace` 只接受尚不存在的新目录；Vim 使用 `-i NONE -n`，撤销和 VimTeX 缓存写入临时工作区；非零 Vim 退出码及 bootstrap dry-run 失败均使套件失败。`--timeout` 必须是正整数。

## Markdown / Marp 改进计划（2026-09-10）

### 状态与范围

阶段 1 清单已固化；阶段 2–4 尚未实施、未通过运行或视觉验收。
本次仅更新本维护文档，不安装依赖、不修改配置，不提交或部署。
上文 LaTeX 记录是历史证据，不代表本计划重新验证了其版本、已知问题或 GUI 状态。

目标：普通 Markdown 写作与 Marp 幻灯片编辑共享已有 Vim 能力，获得可恢复的专注模式、标题导航、模板，以及各自正确的预览。
实施前只读范围为 vim 模块、必要的已安装插件接口、依赖元数据和用户指定的代表性文稿；不扫描无关科研正文。
现有 `.vimrc`、实用手册及未跟踪的维护/测试文件均有既有工作，后续必须增量合并。

### 分阶段待办

- [x] 阶段 1：合并 Markdown / Marp 待办，记录审计约束、拟改文件和验收条件。
- [ ] 阶段 2：确认 Marp CLI 来源和版本、浏览器、输出位置；实现预览、停止、PDF 导出、独立日志及启用/停用。
- [ ] 阶段 3：实现专注模式、源码显示切换、标题目录、快捷键提示；补充并验证两类模板。
- [ ] 阶段 4：评估并接入普通 Markdown 浏览器预览，分别完成科研笔记与 Marp 文稿的视觉验收。

| 优先级 | 待办 | 实施边界 |
|---|---|---|
| 高 | Marp 预览、停止、PDF、日志 | Vim 原生 job 调用 CLI；复用原生 preview/watch，不新增 Vim 插件或自建服务器 |
| 高 | Markdown 专注模式 | 行号、光标行、conceal、软换行按窗口保存/恢复；不改实际换行；覆盖切换 buffer、分屏和退出模式 |
| 高 | 标题导航 | 复用 `:Toc`、`[[`、`]]`；称为标题导航，不冒充精确页码 |
| 高 | 普通 Markdown 公式、图片、Mermaid 预览 | 保留 `Space gm`；单独评估浏览器渲染器，不假定 Marp 与其语法支持相同 |
| 中 | 统一快捷键 | 复用 which-key；核实当前版本的局部提示接口，避免提示与可用命令不一致 |
| 中 | 写作模板 | UltiSnips 公式块、图注、文献笔记骨架；先与已有模板去重 |
| 中 | Marp 模板 | `marpdoc`、`marpslide`、`marpimage`、`marpmath`、`marpnote`；使用内置主题和原生语法 |
| 后置 | 精确分页、按页折叠 | 先验证 Marp 解析结果能否提供可靠源码行映射；不自写完整 Markdown parser |
| 后置 | 双栏主题 | 明确真实主题/CSS 需求后再做，不把双栏当作零依赖模板 |
| 低/候选 | 双向链接、反向链接 | 需求明确后实施；全文搜索只提供候选引用，不等于准确反链 |

### 按键草案（尚未配置）

`Space m` 为 Markdown 共享分组；Marp 专属操作放入其 `a` 子组，避免两种预览争用按键。
保留 `Space gm`、`Space s`、LaTeX 按键、Tab/Shift-Tab 与已有标题跳转。

| 草案 | 功能 |
|---|---|
| `Space mt` | 标题目录 |
| `Space mf` | 专注模式 |
| `Space mc` | 源码符号显示切换 |
| `Space mp` | 普通 Markdown 浏览器预览（阶段 4） |
| `Space map` / `mae` | Marp 预览 / PDF 导出 |
| `Space mas` | 停止 Marp 预览 |
| `Space mal` / `mao` | Marp 预览日志 / 导出日志 |

实施前核对运行期映射和 which-key 接口；此草案不表示命令已经可用。

### 审计后必须遵守的约束

1. 保留 `markdown` filetype。自动识别仅接受文首 YAML 中简单明确的 `marp: true`；复杂形式用手动入口。
   提供 `MarpEnable` / `MarpDisable` / 恢复自动识别入口；手动选择优先于自动识别，作用于当前 buffer。
   打开、保存、文件类型变化时协调启用状态；移除标记能撤销自动启用的映射。
2. `marp*` 模板在普通 Markdown 中也能展开，避免先启用才能插入文档头的循环。
   验证仓库模板确实被运行中的 UltiSnips 加载，不能仅检查文件存在。
3. 不定时或随编辑自动保存。显式预览/导出先更新当前文件，保存失败立即停止；不保存其他 buffer。
   未命名文件须先命名；主题/配置的未保存修改不应被误报为已参与构建。
4. 预览与导出各自维护 job、日志、输出状态；每会话最多一个预览和一个导出，可同时存在。
   重复导出拒绝，不加队列；切换预览须先完成旧任务停止，不能留下竞态或让旧回调覆盖新状态。
5. 只管理自己启动的任务；禁止按名称杀 Marp/浏览器。停止 CLI 不等于浏览器已清理，须运行验收。
6. CLI 参数以列表传递，默认 cwd 为文稿目录。默认禁止隐式发现配置；显式使用已确认的项目配置。
   文稿标记不授予配置执行或本地资源访问权限。可信文稿的本地图片访问按需明确启用，不全局放宽。
7. 优先复用项目固定版本或明确指定的已有 CLI，其次 PATH；没有时记录并安装一种明确版本/来源。
   快捷键不得隐式运行下载或 `npx ...@latest`。依赖缺失明确诊断，不自动安装或升级。
8. PDF 默认采用唯一输出名，交付仍须具有不覆盖语义，不能只依赖事前存在性检查。
   失败保留已有文件；日志明确输出位置。无需引入持久化文件归属数据库。
9. 预览输出位置待相对图片/主题测试后确定。以直接 CLI 为基线，对比独立目录；若失败，先使用明确的同目录专用输出，
   只清理本次创建且仍可确认归属的文件，不为整洁额外引入服务器或资源复制机制。
10. 分开报告“导出完成”与“视觉验收通过”。缺图/资源警告不能被退出码零掩盖；不承诺自动检测全部溢出。

### 预计实施文件（阶段开始前重新冻结）

当前写入白名单只有 `vim/maintenance.md`。后续候选如下，尚未写入：

| 文件 | 目的 |
|---|---|
| `vim/.vimrc` | 模块加载与快捷键提示入口 |
| `vim/.vim/marp.vim` | Marp 状态、识别、预览、导出与日志 |
| `vim/.vim/markdown-writing.vim` | 普通 Markdown 写作与共享导航；规模足够小时直接复用现有配置块 |
| `vim/.vim/UltiSnips/markdown.snippets` | 模板；确认链接路径并保留已有用户 snippets |
| `vim/practical-guide.md`、`vim/CLAUDE.md`、本文件 | 实际操作、依赖、状态与恢复说明 |
| `vim/tests/` 中任务专属文件 | 有意义的回归样例及测试入口，避免覆盖既有测试 |

依赖安装、模板链接及任何模块外文件在实际路径确认后再纳入范围；不顺带改 bootstrap、其他语言配置或更新全部插件。

### 验收门槛

| 层次 | 必测条件 |
|---|---|
| 编辑 | 普通 Markdown/代码不受影响；打开、新建模板、删除标记、手动覆盖能正确切换；按键与提示一致 |
| 专注 | 多次切换、分屏、buffer 切换后恢复原窗口设置；文件字节内容不因显示模式改变 |
| 模板 | 真实 UltiSnips 展开；无重复触发词；空白 Markdown 能展开文档头 |
| 调用 | 未命名/只读保存失败、缺 CLI/浏览器、中文空格路径、默认不执行项目配置 |
| 任务 | 重复预览、切换预览、预览期间导出、重复导出拒绝、导出失败不终止预览 |
| 输出 | 目标已存在及执行中出现均不覆盖；失败不损坏旧文件；相对图片和自定义主题正确 |
| 清理 | 手动关预览窗、停止命令、退出 Vim；无自有遗留任务且原有浏览器不受影响 |
| 视觉 | 代表性中文、公式、本地图片、备注、主题、页数、溢出；普通 Markdown 另验 Mermaid，不假定 Marp 原生支持 |

临时样例放系统临时目录；先直接 CLI，再同样输入经 Vim 调用，结果应一致。
仅配置检查、任务启动或成功退出均不能单独关闭运行/视觉待办。测试失败就修复并重验对应项。
回退仅撤销本次新增配置与链接，保留用户后续修改；不做整文件回退或全局插件清理。

### 依据

- [Marp CLI](https://github.com/marp-team/marp-cli)：preview/watch、配置、浏览器与本地资源访问。
- [Marpit 分页](https://github.com/marp-team/marpit/blob/main/docs/markdown.md)：水平线分页与 CommonMark 上下文。
- [Marpit 备注](https://github.com/marp-team/marpit/blob/main/docs/usage.md#presenter-notes)：备注与指令的区别。
- 本会话 2026-09-10 的方案审计与用户补充的妙言体验待办；尚无本计划的实现验收结果。

### 执行顺序修订与第一阶段结果（2026-09-10）

本节优先于上面的早期 Marp 阶段顺序及按键草案：用户要求先落实截图中的 Markdown 高优先级体验。

- [x] 实现轻量专注模式、源码显示、标题目录及局部菜单。
- [x] 最小配置及真实 `.vimrc` 下自动化回归通过，包含真实 `:Toc` 与 which-key 字典执行。
- [ ] 视觉验收：界面工具明确拒绝访问 Ghostty，不能标为已通过。
- [ ] 下一阶段：普通 Markdown 的公式、图片、Mermaid 浏览器预览。
- [ ] 随后：Marp 预览/导出，再补齐两类模板；精确分页、双栏和反链仍后置。

本次新增 `.vim/markdown-writing.vim`、`tests/markdown-writing-cases.vim`；增量更新 `.vimrc` 与相关文档。
未安装、升级插件或改动语言配置，未提交或部署。显示模式的恢复采用窗口快照，测试期间发现并修复了新分屏继承和换 buffer 恢复问题。

从任意目录运行（将 `<repo>` 替换为 dotfiles 仓库路径）：

```bash
vim -Nu NONE -i NONE -n -es -S <repo>/vim/tests/markdown-writing-cases.vim
vim -Nu <repo>/vim/.vimrc --cmd 'set nocompatible' --cmd 'let g:coc_start_at_startup=0' -i NONE -n -es -S <repo>/vim/tests/markdown-writing-cases.vim
```

退出 0 为断言通过，非零为失败。最小配置不验收插件集成；第二条使用已安装插件验收实际目录和菜单。
日常使用须重启 Vim；若回退，先检查后续改动，只撤销本次加载行、模块及对应文档/测试增量。

### Markdown 浏览器预览接入（2026-09-10，partial）

- 已安装固定提交的 markdown-preview.nvim，依赖使用现有 Node/npm 安装；插件安装钩子已登记。
- 已配置手动启动、回环监听、组合预览和原生刷新；局部菜单 `mp/ms` 启动/停止。
- 真实 Vim 启动 HTTP 服务、页面响应、监听范围及退出清理已检查，写作回归通过。
- 未关闭视觉验收待办：浏览器工具报 ERR_BLOCKED_BY_CLIENT；内容刷新协议探针超时，尚不能证明未保存更新和标签复用。
- 下一步应先完成此预览运行/视觉验收，再转 Marp；操作见实用手册最新小节。

### 预览运行验收补充（2026-09-10）

- 初始刷新探针超时已定位为测试事件错误：插件监听 CursorMoved/CursorHold（含插入模式），不是 TextChanged。修正探针后初始内容和未保存刷新均通过，无需改插件实现。
- Socket.IO 实际客户端验证重复启动发出 change_bufnr 复用请求、切换 buffer 收到新内容、停止断开连接；停止后 server status=-1，无原端口监听。
- 本地 SVG 从中文空格目录按插件真实图片 URL 返回，字节与源文件一致。第一次探针误加斜线返回 404，按 image.js 的实际 URL 规则修正后通过。
- 停止测试最初等待 close_page 超时；实际停止会终止服务并断开连接，修正为 disconnect 后通过。不能由此承诺浏览器标签自动关闭。
- 上述检查为服务/协议验收，不等于视觉验收。公式、Mermaid 和排版的浏览器视觉检查仍受此前 ERR_BLOCKED_BY_CLIENT 限制，未标记完成。
- 所有样例只在临时目录操作；测试 Vim 已退出。本轮只更新验收记录，没有改变已安装插件或运行配置。

### 用户视觉验收（2026-09-10）

用户在本机浏览器查看测试预览后确认“都正常”。本次样例中的中文、行内/独立公式、本地 SVG 图片、Mermaid 与代码块视觉验收完成，证据来源为用户确认，并非代理截图检查。
结合此前服务/协议验收，普通 Markdown 预览本轮样例验收完成；不外推到所有公式命令、Mermaid 新语法或大型文稿。后续进入 Marp 预览与 PDF 导出阶段。

### 2026-09-11 配置审计修复

已修复光标恢复 E116、映射行尾注释和 autowrite；添加可切换拼写、局部模板及提示说明。
Marp 修复重载清空状态、旧通道污染、启动失败判断、空失败输出残留和重复查看日志过期。

验证入口：

- `tests/markdown-writing-cases.vim`：使用实际 vimrc，原有写作/目录/菜单回归。
- `tests/editor-fixes-cases.vim`：使用实际 vimrc，光标恢复、映射内容、关闭自动保存、拼写切换、八个真实 UltiSnips 展开。
- `tests/marp-cases.vim`：`vim -Nu NONE -i NONE -n -es -S <repo>/vim/tests/marp-cases.vim`；模拟 CLI，不启动浏览器。覆盖重载后重复任务保护、日志刷新、不同通道隔离、唯一输出及失败空输出清理。固定等待改为有上限的任务完成等待，避免原先短等待波动。

前两项使用 `vim -Nu <repo>/vim/.vimrc --cmd 'set nocompatible' --cmd 'let g:coc_start_at_startup=0' -i NONE -n -es -S <test>`。
五次空会话启动（真实配置，未禁用 CoC，进入 Ex 后立即退出）耗时 104/83/83/82/84 ms，中位数 83 ms；不代表语言服务索引或 GUI 响应。未因此加入懒加载。
浏览器相关暂停继续有效；没有启动 Chrome/Firefox，没有安装或升级依赖，没有提交或部署。

### 当前剩余工作（2026-09-11，优先于早期阶段草案）

- [x] Markdown 专注/源码/标题导航、拼写开关和模板配置。
- [x] 普通 Markdown 预览服务/协议验收及用户确认的图文视觉验收。
- [x] Marp 命令、独立任务日志、唯一输出与模拟回归。
- [x] 真实 Marp CLI 无浏览器 HTML 转换和 watch 保存更新：临时样例从 Watch baseline 改为 Watch refreshed，生成 HTML 同步更新；测试监听已停止。
- [ ] 用户确认浏览器修复后，恢复 Firefox 实际预览、PDF 导出、图片/公式/分页与进程清理验收。
- [ ] 分页折叠、双栏主题、双向链接：原计划后置候选，尚未纳入本轮实现。

Marp 操作和依赖重建入口已补到实用手册。当前未启动浏览器，没有替用户修改 Firefox profile；浏览器恢复问题已询问用户，等待确认。


### Firefox 恢复验收（2026-09-11）

用户恢复浏览器测试授权后，完成真实 Vim 配置到 Firefox 的验证：

- [x] 修复 CLI 等待 stdin：预览和导出均显式传入 `--no-stdin`。
- [x] PDF 导出使用任务独占的临时 `MOZ_APP_DATA`，退出回调清理；不修改个人浏览器配置。
- [x] 实际 Firefox 预览、左右翻页、本地 SVG、中文和公式显示正常。
- [x] 修改临时样例后 Firefox 自动刷新，并保持第二页。
- [x] 实际 Firefox 两页 PDF 导出成功，逐页渲染检查通过。
- [x] 模拟 Marp 回归通过。

本节取代此前浏览器暂停状态。验收范围为两页 default 主题样例；大型文稿、自定义主题及演讲备注仍未进行视觉验收。没有启动 Chrome、升级依赖或提交。
