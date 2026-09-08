# vim 模块

> 面包屑：[dotfiles](../CLAUDE.md) > vim

## 职责

Vim 编辑器配置，基于 vim-plug 管理插件，提供轻量编辑、搜索和语言服务入口；Codex、运行与测试使用独立应用或终端。

## 文件清单

| 文件 | symlink 目标 | 用途 |
|------|-------------|------|
| `.vimrc` | `~/.vimrc` | Vim 主配置 |
| `.vim/coc-settings.json` | `~/.vim/coc-settings.json` | Python / Julia / LaTeX 语言服务配置 |

实用操作见 [Vim 实用手册](practical-guide.md)。

## 主要配置项

- **Leader 键**：`<Space>`
- **插件管理器**：vim-plug（`plug#begin` / `plug#end`）
- **补全**：coc.nvim（LSP 客户端）
- **文件树**：NERDTree（`<F3>` 切换）
- **模糊搜索**：fzf + fzf.vim（`<C-p>` 文件，`<C-f>` 全文，`<C-a>` buffer）
- **终端**：vim-floaterm（`<F7>`/`<F8>`/`<F9>`/`<F12>`）
- **Snippet**：UltiSnips + vim-snippets（`<Tab>` 触发/前跳，`<S-Tab>` 后跳）
- **状态栏**：vim-airline
- **快捷键提示**：vim-which-key
- **自动格式化**：vim-autoformat（仅 `<F2>` 手动触发；无可用格式化器时显示诊断，禁用空白与缩进回退）

## 插件列表

| 插件 | 功能 |
|------|------|
| `preservim/nerdtree` | 文件树 |
| `mhinz/vim-startify` | 启动页 |
| `ryanoasis/vim-devicons` | 图标 |
| `junegunn/fzf` + `fzf.vim` | 模糊查找 |
| `neoclide/coc.nvim` | LSP 补全 |
| `liuchengxu/vim-which-key` | 快捷键提示 |
| `jiangmiao/auto-pairs` | 括号自动配对 |
| `mg979/vim-visual-multi` | 多光标 |
| `tpope/vim-surround` | 包裹操作 |
| `voldikss/vim-floaterm` | 浮动终端 |
| `SirVer/ultisnips` | Snippet 引擎 |
| `honza/vim-snippets` | Snippet 集合 |
| `vim-autoformat/vim-autoformat` | 自动格式化 |
| `vim-airline/vim-airline` | 状态栏 |

## 依赖

- 工具：`vim`（9.0.0438+，满足当前 CoC 要求），各语言格式化工具（供 autoformat 调用）
- 插件管理器：vim-plug（需手动安装至 `~/.vim/autoload/plug.vim`）
- coc.nvim 需要 Node.js

## 修改指南

- 普通配置修改不需要更新插件；只有新增插件时运行 `:PlugInstall`，升级另行安排。保存工作后重启 Vim 验证。
- coc 插件通过 `:CocInstall coc-<name>` 安装，配置在 `:CocConfig`
- Snippet 自定义文件放在 `~/.vim/UltiSnips/<filetype>.snippets`

## 第一轮编辑约定

- `hidden` 允许切换未保存的 buffer，不自动保存。
- 搜索默认忽略大小写，输入大写字符时区分大小写。
- 持久撤销保存到 `${XDG_CACHE_HOME:-~/.cache}/vim/undo`，不进入项目。
- Python 默认四空格；其他文件类型保持既有规则，不在保存时转换缩进。
- `gd` / `gr`：定义 / 引用；`[g` / `]g`：上一条 / 下一条诊断。
- `K`：语言服务可用时显示悬浮文档，否则执行原生 K（遵守 `keywordprg`）。
- `Space rn` / `Space ca`：重命名 / 光标处代码操作。
- `Space d` / `Space s`：诊断列表 / 当前文档符号。
- Tab / Shift-Tab 保留给 UltiSnips，Enter 保留 CoC 补全确认。
- 第一轮不安装语言服务，不新增或升级 Vim 插件；语言服务入口不代表各语言已验收。
- Codex 独立使用；外部修改后先处理 Vim 未保存内容，再检查磁盘变化，禁止强制覆盖。

## 第二轮 Python 接入（2026-09-08）

- 安装 `coc-pyright 1.1.413`；重建时可用 `:CocInstall coc-pyright@1.1.413`。其他扩展登记不变，不向 Python 环境安装编辑器依赖。
- [CoC 配置](.vim/coc-settings.json)：`python.pythonPath=python`、仅打开文件的诊断、basic 类型检查、关闭外部 lint；保留 Pyright 自身诊断。
- 一个 Vim 会话对应一个项目环境，先激活 Conda 或已有 uv `.venv` 再启动 Vim。
- 当前扩展优先读取有效 `VIRTUAL_ENV`，其次 `CONDA_PREFIX`，随后尝试项目环境，最后使用配置的解释器。避免混合激活；`python.pythonPath` 并不覆盖所有环境自动检测。
- 使用 `:CocCommand workspace.showOutput Pyright` 核对 `Using python from` 与 `Setting pythonPath`。在浮动终端激活另一个环境不会更新父 Vim 环境。
- 打开 Python 文件或发现 `pyproject.toml` 等项目标记都可能激活 Pyright；并非严格仅按文件类型启动。
- F2、现有 16 个 Vim 插件和第一轮设置不变。该轮未接入 Julia/LaTeX；Julia 现见第三轮。
- 验收、性能与已知日志告警见实用手册的第二轮记录。

## 第三轮 Julia 接入（2026-09-08）

- 使用 CoC 原生 `languageserver.julia`，不新增 Vim 插件；仅 Julia 文件且祖先目录存在 `Project.toml` / `JuliaProject.toml` 时启动。
- [工具环境](.vim/julia-language-server/Project.toml)及其 Manifest 固定 LanguageServer 4.5.1、Julia 1.12.7；[启动入口](.vim/julia-language-server/start.sh)显式使用 `julia +1.12.7`，从文件目录选择最近项目。
- `~/.vim/julia-language-server` 链接此工具目录。工具使用标准 `~/.julia` depot、隔离 LOAD_PATH、一个线程、不读取 startup.jl；不会向被编辑项目安装依赖。缺少固定运行时、工具依赖或项目不满足 Julia compat 时明确失败，不自动安装或切换默认版本。
- Project 中的 `preferences.LanguageServer.precompile_workload=false` 关闭 4.5.1 会遗留后台 IO 的预编译工作负载，保留正常模块缓存。不要删除此项或随意更新依赖；5.0.0 在本机 CoC 测试中出现旧版本诊断无法清除的问题，未采用。
- 一个 Vim 会话只处理一个 Julia 项目；跨项目请重新启动。首次启动/索引有明显资源成本，具体数据与验证边界见实用手册第 12 节。
- Python 配置、`.vimrc`、F2、插件及 Julia 全局默认通道保持原样。升级遵循 Julia 维护 skill：独立候选、风险评估、功能验收后切换。

## 第四轮 LaTeX 接入（2026-09-08）

- 安装 Homebrew `texlab 5.26.0`，使用原生 CoC `languageserver.texlab`，没有增加 Vim 插件。
- CoC 将 Vim `tex` 映射为 `latex`，因此服务匹配 `latex` / `plaintex` / `bib`。优先识别 `.latexmkrc`、`latexmkrc`、`.git`，没有项目标记的独立文件也可使用。
- 关闭保存自动构建、构建后自动 PDF 跳转与额外 ChkTeX 检查，保留 Texlab 自身语法诊断。编译沿用项目命令；不强制指定 XeLaTeX 或改变 F2。
- 补全、标签/文献导航、引用、标签重命名编辑、章节符号、BibTeX 补全和诊断刷新已通过临时项目验收。维护与回退见手册第 13 节。
