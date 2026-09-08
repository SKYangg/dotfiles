# Vim 实用手册

适用：本机 Vim 9.2，第四轮 Python / Julia / LaTeX 语言服务配置。更新：2026-09-08。

配置来源：[.vimrc](.vimrc)；维护说明：[CLAUDE.md](CLAUDE.md)。本手册描述现有行为，不把待安装的功能列为已完成。

## 先记住这十个操作

| 目的 | 操作 |
|---|---|
| 回到普通模式 | `Esc` |
| 开始输入 | `i` |
| 保存 | `:w`，再按 Enter |
| 保存并退出当前窗口 | `:wq` |
| 找文件 | 普通模式 `Ctrl-P` |
| 找内容 | 普通模式 `Ctrl-F` |
| 切换已打开文件 | 普通模式 `Ctrl-A` |
| 撤销 / 重做 | 普通模式 `u` / `Ctrl-R` |
| 开关文件树 | 普通模式 `F3` |
| 开关浮动终端 | `F12` |

`Space rn` 表示依次按空格、r、n；`Ctrl-W h` 表示先按 Ctrl-W，再按 h。带冒号的命令从普通模式输入，最后按 Enter。功能键被 macOS 用作系统控制时，尝试同时按 Fn。

## 1. 打开项目与编辑

在终端进入目标项目目录，再运行 `vim` 或 `vim 文件名`。先在项目根目录启动，文件搜索和终端工作目录更容易保持一致。路径带空格时用引号包住。

在 Vim 内用 `:pwd` 检查工作目录。现有配置没有统一的自动项目根目录切换机制，不要默认全文搜索会自动覆盖整个仓库。

| 操作 | 普通模式按键 |
|---|---|
| 光标前 / 后开始输入 | `i` / `a` |
| 行尾开始输入 | `A` |
| 下方 / 上方新建一行 | `o` / `O` |
| 单词移动 | `w` / `b` |
| 行首 / 第一个非空字符 / 行尾 | `0` / `^` / `$` |
| 文件开头 / 结尾 | `gg` / `G` |
| 跳到第 42 行 | `42G` 或 `:42` |
| 修改当前单词内容 | `ciw` |
| 删除一行 / 复制一行 | `dd` / `yy` |
| 粘贴到后面 / 前面 | `p` / `P` |
| 重复上次修改 | `.` |

`v` 开始字符选择，`V` 开始整行选择；移动光标扩大范围，再用 `y` 复制、`d` 删除或 `c` 修改。`Esc` 取消选择。

Vim 默认寄存器与系统剪贴板分开。需要系统剪贴板时显式使用 `"+y`、`"+p`；若当前构建或终端不支持，使用终端自己的复制粘贴操作，不要把 `yy` 当成系统复制。

## 2. 文件搜索与切换

| 按键 | 当前配置的功能 |
|---|---|
| `Ctrl-P` | fzf 文件搜索 |
| `Ctrl-F` | ripgrep 内容搜索 |
| `Ctrl-A` | 搜索已打开的 buffer |
| `Space` 后稍等 | WhichKey 显示已有快捷键入口 |
| `Ctrl-O` / `Ctrl-I` | 在跳转历史中后退 / 前进 |

搜索框输入关键词，用方向键选择、Enter 打开；Esc 退出。文件是否可见取决于搜索工具及忽略规则，不能把“搜不到”直接理解成文件不存在。

当前 `Ctrl-A` 覆盖原生数字递增，`Ctrl-F` 覆盖原生向下翻页。翻页可使用 `Ctrl-D` / `Ctrl-U`（半页）。

buffer 是内存中的文件内容，窗口是查看 buffer 的区域；切换 buffer 不等于保存。当前已启用 `hidden`，允许保留修改后切走。

## 3. 文件树与分屏

普通模式按 F3 打开文件树。以下操作在文件树窗口内使用：

| 按键 | 功能 |
|---|---|
| `o` / Enter | 打开文件或展开目录 |
| `i` / `s` | 水平 / 垂直分屏打开 |
| `t` | 新标签页打开 |
| `I` | 切换隐藏文件显示（当前默认显示） |
| `q` | 关闭文件树窗口 |

普通编辑窗口中，`:split` 水平分屏，`:vsplit` 垂直分屏。用 `Ctrl-W h/j/k/l` 向左/下/上/右切换窗口，`Ctrl-W w` 轮换窗口，`Ctrl-W =` 均分尺寸。

## 4. 搜索与替换

| 操作 | 输入 |
|---|---|
| 当前文件向后搜索 | `/关键词` |
| 下一个 / 上一个结果 | `n` / `N` |
| 搜索光标下单词 | `*` |
| 暂时取消搜索高亮 | `:nohlsearch` |
| 全文件逐项确认替换 | `:%s/旧文本/新文本/gc` |

搜索默认忽略大小写；模式含大写字母时区分大小写。搜索和替换使用 Vim 正则，`.`、`*` 等可能具有特殊含义。替换命令的 `c` 会逐项确认：`y` 替换、`n` 跳过、`q` 停止。

## 5. 保存与撤销

| 命令 / 按键 | 功能 |
|---|---|
| `:w` | 保存当前 buffer |
| `:wa` | 保存所有已修改 buffer；使用前确认修改范围 |
| `:q` | 关闭当前窗口；有未保存修改时通常会阻止 |
| `:wq` | 保存并关闭当前窗口 |
| `:q!` | 放弃当前窗口相关的退出保护；仅在明确不要修改时使用 |
| `u` / `Ctrl-R` | 撤销 / 重做 |
| `:ls` | 查看 buffer 列表，`+` 表示有修改 |

持久撤销已开启：保存文件后，重开同一文件通常仍可撤销。撤销记录位于 `${XDG_CACHE_HOME:-~/.cache}/vim/undo`，不进入项目；它不替代备份或 Git，也不保证恢复未保存且意外丢失的内容。

保存不触发自动格式化。原来的 `W` / `w!!` 提权保存命令已移除。

## 6. 片段与括号

| 操作 | 按键 / 命令 |
|---|---|
| 展开匹配片段 / 前往下一个占位符 | 插入模式 `Tab` |
| 返回上一个占位符 | `Shift-Tab` |
| 编辑当前文件类型片段 | `:UltiSnipsEdit` |
| 给当前单词加双引号 | 普通模式 `ysiw"` |
| 将双引号改成单引号 | 普通模式 `cs"'` |
| 去掉包围的双引号 | 普通模式 `ds"` |

片段需要匹配触发词与文件类型；Tab 不保证在任意位置展开片段。自定义片段保存在 `~/.vim/UltiSnips/`。括号插件还会包装 Enter 行为，因此 Enter 的有效映射可能显示为 AutoPairs，而非直接显示 CoC。

## 7. 代码理解与补全

以下入口已经配置，但具体功能需要对应语言服务器支持。当前 CoC 扩展包括 JSON、TypeScript/JavaScript、marketplace 和 coc-pyright。Python 已通过 Conda/uv 临时样例的语言服务验收；Julia 已通过第三轮小项目验收（见第 12 节）；LaTeX 已接入 Texlab（见第 13 节）。

| 普通模式按键 | 功能 |
|---|---|
| `gd` / `gr` | 定义 / 引用 |
| `K` | 有 hover 服务时显示文档，否则执行原生 K，遵守文件类型的 `keywordprg` |
| `[g` / `]g` | 上一条 / 下一条诊断 |
| `Space rn` | 重命名符号 |
| `Space ca` | 光标处代码操作 |
| `Space d` | 诊断列表 |
| `Space s` | 当前文档符号列表 |

插入模式中，CoC 补全框可见时 Enter 确认建议，否则正常换行。Tab 留给片段，不承担统一的补全菜单导航。

排查入口：`:CocInfo` 查看服务状态，`:CocList extensions` 查看扩展，`:set filetype?` 核对当前文件类型。当前没有 Vim 内的 AI 灰字补全或 Codex 桥接。

## 8. 手动格式化与缩进

普通模式 F2 调用 Autoformat，默认处理整个文件。首次用于重要文件前，先保存可恢复版本；格式化后检查差异，不满意用 `u` 撤销。不要假定可视选择一定把外部格式化器限制在选择范围内。

没有可用格式化器时会显示诊断；当前关闭了隐式重新缩进、Tab 转换和行尾空格清理。F2 不负责安装格式化器。普通保存继续保持原内容，包括 Markdown 行尾双空格。

Python 默认四空格；其他语言保持既有文件类型规则。可用 `:setlocal expandtab? shiftwidth? softtabstop? tabstop?` 检查当前值。这是默认配置，不自动把已有代码全部转换成四空格。

## 9. 终端、运行与 Codex

| 按键 | 功能 |
|---|---|
| `F7` | 新建浮动终端 |
| `F8` / `F9` | 上一个 / 下一个浮动终端 |
| `F12` | 显示 / 隐藏浮动终端 |

终端内执行项目已有的运行、测试和 Git 命令。运行前确认目录与 Python/Julia 环境，运行命令仍由你选择；Python 语言服务会识别启动时的激活环境，但不会自动替终端切换环境，也没有一键测试配置。F12 隐藏终端不等于停止其中的进程。

Vim 终端中按 `Ctrl-W N`（大写 N）进入终端普通模式，便于滚动查看输出；按 `i` 返回终端输入。不要把在 shell 中按 Esc 当成回到 Vim 普通模式。

Codex 使用现有独立应用或终端：

1. 保存 Vim 中准备交给 Codex 的文件。
2. 明确告诉 Codex 目标和允许修改的范围。
3. Codex 完成后检查差异。
4. Vim 中执行 `:checktime` 检查磁盘变化，按提示决定是否加载；不是自动强制重载。

如果 Vim 同时有未保存修改，先保存到其他文件或处理差异，再加载外部版本。不要直接使用 `:edit!` 覆盖内存中的修改。

## 10. 常见问题

| 现象 | 先检查 |
|---|---|
| 快捷键变成普通字符 | 是否处于插入模式？先按 Esc；终端输入模式另见上一节 |
| F2 / F3 / F12 被系统接管 | 尝试 Fn，检查终端和 macOS 功能键设置 |
| gd、重命名、诊断不可用 | `:CocInfo`、`:CocList extensions`、`:set filetype?`；该语言是否已接通 |
| F2 提示没有格式化器 | 这是预期保护；检查项目所需工具，不反复保存或全局安装依赖 |
| 不知道是谁占用了按键 | `:verbose nmap gd`、`:verbose imap <Tab>`、`:verbose imap <CR>` |
| 全文搜索范围不对 | `:pwd`，检查是否从项目根目录启动 |
| 文件被外部修改 | 先处理未保存内容，再 `:checktime` |
| 修改配置后行为仍旧 | 保存工作后重启；删除配置行不会清除旧会话已经注册的命令或映射 |
| 想查看刚才的提示 | `:messages` |

## 配置维护边界

- 现有 16 个 Vim 插件；本轮没有新增或升级。
- 常用配置修改不要求 `:PlugUpdate`，不要把更新全部插件当成重载设置。
- 日常编辑实际维护的 dotfiles `.vimrc`，保留 `~/.vimrc` 软链接。
- 本手册依据当前配置与本机插件帮助编写；快捷键入口检查不能替代真实语言服务、终端 UI 或具体格式化器验收。

## 11. Python 环境与第二轮验收记录

### 日常启动

Conda：先 `conda activate 环境名`，进入项目根目录，再运行 `vim`。

uv：环境已存在时，从项目根目录执行 `source .venv/bin/activate`，再运行 `vim`。不要为了打开编辑器自动执行 `uv sync`；依赖维护属于项目本身。

一个会话对应一个环境。切换时保存并退出 Vim，再从新环境启动。避免同时残留 `VIRTUAL_ENV` 和 `CONDA_PREFIX`：当前扩展优先采用有效的 `VIRTUAL_ENV`，再采用 Conda 环境。

在 Vim 执行 `:CocCommand workspace.showOutput Pyright`，核对 `Using python from` / `Setting pythonPath`。`:echo exepath('python')` 只反映 Vim 的 PATH，不单独证明语言服务器的最终选择。

### 当前配置

[配置源](.vim/coc-settings.json)通过软链接提供给 `~/.vim/coc-settings.json`，可由 `:CocConfig` 打开。

- `python.pythonPath: "python"`：解释器回退项，不固定本机环境路径。
- `python.analysis.diagnosticMode: "openFilesOnly"`：优先诊断打开文件，仍可能读取导入依赖。
- `python.analysis.typeCheckingMode: "basic"`：基础类型检查；既有项目配置可能覆盖。
- `python.linting.enabled: false`：关闭外部 lint，不关闭 Pyright 自身诊断。

### 实测证据（2026-09-08）

安装版本：coc-pyright / Pyright 1.1.413。CoC 扩展目录与原有三个扩展共存，未修改 Vim 插件清单。

测试在独立临时目录进行，只借用已有 Conda work（Python 3.10.15）和 uv（Python 3.14.2）解释器；进程设置对应激活环境变量与 PATH，不修改原环境或科研项目。

两边均通过：CoC 到 Pyright 的真实请求、跨文件定义、引用、hover、重命名返回的跨文件编辑、成员补全、类型错误诊断及修复后诊断清除。NumPy 在 Conda 中解析成功，在未安装 NumPy 的 uv 环境中产生缺失导入诊断，符合环境实际状态。

重命名验证了返回编辑的位置与文件，未以真实终端 UI 演练重命名对话框或多 buffer 应用；补全验证了服务返回结果，未对弹窗做视觉验收。`.vimrc` 字节未变，保存/按键仍沿用第一轮配置。

| 场景 | 本次观测 |
|---|---|
| 无项目标记的空目录（3 次） | 配置与插件加载到测试入口约 72–83 ms；CoC 初始化约 281–292 ms |
| Python 小样例（一次完整验收/环境） | 从 Vim 早期初始化计时，到首次补全请求返回：Conda 约 1.02 s，uv 约 0.81 s；此前执行了导航等请求，不是纯补全延迟 |
| 空目录进程内存 | Vim 约 20 MiB，CoC 约 81 MiB；未观察到 Pyright 子进程 |
| Python 样例进程内存 | Vim 约 46 MiB，CoC 约 110–114 MiB，Pyright 约 124–151 MiB |

内存是每 0.2 秒采样的各进程 RSS 峰值，不能直接相加当作同时峰值，也不是整机实际增量。测试使用无界面 Vim，不代表终端首帧时间；大型科研项目及大量依赖的性能未验收。

已知限制：服务日志在初始诊断阶段出现 `Lost request state in diagnostic pull model. Clearing diagnostics`。仅诊断场景中也复现；诊断实际产生和修复后清除均通过。目前作为非阻塞上游交互告警记录，未通过关闭诊断掩盖它。若实际使用出现诊断持续缺失，应重新排查，不把当前小样例通过外推为所有项目正常。

### 回退

使用 `:CocUninstall coc-pyright` 移除第二轮扩展，并仅移除四个 `python.*` 配置项。第三轮已共用此配置文件，请保留 Julia 条目、配置源及软链接。恢复对应文档差异即可，第一轮 `.vimrc` 不需要回退。

原件、扩展安装前登记和详细测试结果保存在一次性系统临时目录中，可能被系统清理；本节保留可长期查阅的结果摘要。未修改项目依赖，未提交 Git。

## 12. Julia 项目与第三轮验收记录

### 日常使用

进入已有 Julia 项目，打开 `.jl` 文件，例如 `vim src/main.jl`。文件上级目录须有 `Project.toml` 或 `JuliaProject.toml`；单独的 `.jl` 文件不会启动服务，不要为了补全自动创建项目。

沿用 `gd` 定义、`gr` 引用、`K` 文档、`Space rn` 重命名、`Space d` 诊断、`Space s` 文档符号、`[g` / `]g` 诊断跳转。补全仍由 CoC 提供，Enter 确认，Tab 留给 snippets。F2 没有接入新的 Julia 格式化器。

用 `:CocInfo` 查看状态；用 `:CocCommand workspace.showOutput languageserver.julia` 查看启动日志中的运行时与项目目录。服务启动期间仍可编辑文件。一个会话对应一个 Julia 项目；切换项目先保存并退出。临时停用可执行 `:call CocAction('toggleService', 'languageserver.julia')`，再执行一次恢复。

### 固定版本与环境边界

[工具 Project](.vim/julia-language-server/Project.toml)、[Manifest](.vim/julia-language-server/Manifest.toml)和[启动脚本](.vim/julia-language-server/start.sh)是一组维护对象：Julia **1.12.7**、LanguageServer **4.5.1**。启动明确指定精确 Juliaup 版本，不跟随 `release` 通道；全局默认通道没有改变。

工具使用独立 Project、`JULIA_LOAD_PATH=@:@stdlib`、标准 `~/.julia` depot、单线程、禁用 startup.jl 与历史文件。Conda/uv 激活仍供 Python 使用，不会改变本服务所选 Julia 版本。科研项目的依赖仍由项目自行维护；语言服务会读取项目并索引依赖，但不替项目安装或升级。项目 Julia compat 排斥 1.12.7 时服务拒绝启动；缺失 compat 不代表已证明兼容。

4.5.1 的预编译工作负载在本机遗留后台 IO，工具 Project 使用包支持的 `precompile_workload=false` 关闭该工作负载，正常模块预编译仍保留。不要用每次启动跳过缓存代替这个配置，也不要直接更新到 5.0.0：该候选返回旧文档版本的空诊断，CoC 保留了已修复的错误提示。

新机器恢复：先建立配置和工具目录链接，再显式安装和实例化；不要在 Vim 启动脚本中运行这些维护命令：

```sh
juliaup add 1.12.7
JULIA_DEPOT_PATH="$HOME/.julia:" JULIA_LOAD_PATH='@:@stdlib' \
  julia +1.12.7 --startup-file=no --project="$HOME/.vim/julia-language-server" \
  -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
```

升级前评估 Julia、包兼容性、缓存重建和资源成本；保留当前精确版本及完整工具环境，在独立目录验证补全、跳转、引用、重命名与诊断刷新后再切换。不要把修改 Manifest 的 Julia 版本字段当作升级。

### 本机验收与开销（2026-09-08）

临时小型 Julia 项目通过真实 CoC 请求验证：跨文件定义、引用、hover、重命名返回的跨文件编辑、补全、文档符号、缺失引用诊断，以及真实按键修改并保存后诊断清除。重命名未通过 UI 应用到多 buffer；补全弹窗未做视觉验收。大型科研项目、项目依赖的语义分析和科学计算正确性未验收。

普通文本与无项目的 `.jl` 文件测试未启动 Julia；项目不兼容时明确失败。候选与正式入口均在退出后未发现残留服务进程。`.vimrc` 与 Python 原有配置值不变。

正常缓存候选测试：服务就绪约 **13.1 秒**；导航等请求后取得首次补全约 **27.5 秒**，不是单次补全延迟。包级预编译开关使预编译在约 23 秒完成；不用正常缓存的候选需要约 53 秒才就绪，未采用。

采样到主 Julia 进程 RSS 峰值约 **790 MiB**，索引子进程约 **562 MiB**，Vim 约 50 MiB、CoC 约 83 MiB。各进程峰值不发生在同一时刻，不能相加为同时峰值或整机实际增量。Julia 项目的按需服务明显重于普通编辑；以上不是大型项目上限。

正式软链接入口复验同样通过全部功能检查：服务就绪约 **8.5 秒**，导航等请求后取得首次补全约 **17.3 秒**；主 Julia RSS 峰值约 **763 MiB**，索引子进程约 **655 MiB**。两次测量受缓存状态影响，不是稳定性能承诺。正式入口的普通文本、无项目 Julia、退出清理均通过。

### 停用与回退

保存工作，删除 CoC 配置中本轮的 `languageserver.julia` 条目后重启 Vim，即恢复第二轮行为；保留所有 Python 配置与其他已有语言服务条目。工具目录和精确 Julia 版本可以暂留，未启用时不会自动运行。不要删除整个 CoC 配置文件，也不要为了回退清理共享 depot 或全局 Julia 通道。

本轮原件和候选测试保存在一次性系统临时目录中，系统可能清理该目录；本节保留持久的结果摘要。未修改科研项目环境，未提交 Git。

## 13. LaTeX 与 BibTeX 支持

进入论文目录，使用 `vim main.tex`，或直接打开 `.tex` / `.bib` 文件。无需新建项目标记。服务通过 `\input`、`\include`、文献文件关联分析；复杂多主文件项目应检查跳转结果，不能仅凭 Git 根目录推定论文主文件。

- 引用补全：在 `\ref{...}` 中补全标签，在 `\cite{...}` 中补全文献键；`.bib` 支持条目类型补全。Enter 确认，Tab 仍用于 snippets。
- `gd`：从标签引用跳到标签定义，从文献键跳到 BibTeX 条目。
- `gr`：查找引用；`Space rn`：重命名标签及其引用。
- `Space s`：章节符号；`Space d`、`[g` / `]g`：诊断列表与跳转。
- `K` 仍是语言服务文档入口，具体内容取决于光标对象和服务返回，不保证所有 LaTeX 命令都有说明。

`:CocInfo` 查看状态，`:CocCommand workspace.showOutput languageserver.texlab` 查看服务输出。临时切换开关：`:call CocAction('toggleService', 'languageserver.texlab')`。

### 编译与预览

保存不会自动构建，也不会自动打开 PDF。浮动终端中使用项目已有编译命令，例如项目明确采用 XeLaTeX 时执行 `latexmk -xelatex main.tex`；其他项目沿用其原有引擎和配置。Texlab 的语法诊断不替代完整 LaTeX 编译检查。

本轮未增加 PDF 正反向同步、自动构建、额外 ChkTeX 或新的 F2 格式化规则；没有修改现有论文文件或编译配置。

### 安装、验收与维护

本机安装 `texlab 5.26.0`（Homebrew）；新机器可显式执行 `brew install texlab`，再验证版本和功能。没有固定 Homebrew 更新策略，`brew upgrade` 可能更新它；不在 Vim 启动时自动安装或升级。配置位于 [coc-settings.json](.vim/coc-settings.json)。Python、Julia 和 `.vimrc` 保持原样。

临时多文件样例通过真实 CoC 请求验证：标签/文献引用补全，跳转到章节与 BibTeX 文件，引用位置，跨文件标签重命名返回编辑，章节符号，BibTeX 条目类型补全，额外右括号诊断及修复后清除。未以 UI 演练补全弹窗或应用多文件重命名；真实大型论文项目尚未验收。

候选两次观察服务就绪约 0.95–2.32 秒，Texlab 采样 RSS 峰值约 11–17 MiB。测试为无界面 Vim、小型项目，不代表所有项目的启动速度或上限。测试没有产生 PDF、aux 或构建日志。详细证据及原件位于一次性系统临时目录中（可能被系统清理）。

正式入口复验同样全部通过：服务就绪约 1.73 秒，Texlab RSS 峰值约 17.6 MiB；退出后无残留进程，普通文本未启动 Texlab。JSON、原有配置值、`.vimrc` 字节一致性及文档链接检查通过。

回退：保存工作，移除 `languageserver.texlab` 配置条目后重启 Vim；保留 Python/Julia 条目。Texlab 程序可以暂留，未启用时不自动运行。

配置依据：[Texlab 官方配置说明](https://github.com/latex-lsp/texlab/wiki/Configuration)。

## 14. LaTeX 编译与 Skim 预览（VimTeX）

本节替代此前自定义构建器说明。保存工作后重启 Vim；Skim 如果原先已运行，保存其工作并重新打开，使新的同步设置生效。

| 普通模式按键 | 功能 | 命令 |
|---|---|---|
| `Space lb` | 保存当前文件并单次编译 | `:LatexBuild` |
| `Space lv` | 打开 Skim 并定位到当前源码对应 PDF 位置 | `:VimtexView` |
| `Space ls` | 停止当前项目构建 | `:VimtexStop` |
| `Space lo` | 查看构建输出 | `:VimtexCompileOutput` |

`:LatexBuildLog` 保留为构建输出的兼容入口。错误仍用 `:copen` 打开、Enter 跳转、`:cnext` / `:cprevious` 切换；日志解析由 VimTeX 维护。

### 主文件与构建

主文件含 `\documentclass`。子文件前 50 行指定主文件：

```tex
% !TeX root = ../main.tex
```

路径相对于注释所在文件；支持空格路径。`Space lb` 保留严格检查，主文件不明确或与 VimTeX 识别不同则提示，不猜测。构建前保存当前文件，其他打开且修改过的 TeX/Bib/sty/cls/latexmkrc buffer 需先保存。VimTeX 的原生命令不经过这个保存保护，日常请使用 `Space lb`。

VimTeX 使用 latexmk **单次构建**，不会启用持续编译或保存自动构建。项目 `.latexmkrc` 控制引擎和输出目录，构建增加 `-synctex=1`、非交互模式与文件行号输出。同一项目重复触发会拒绝启动第二个构建；停止使用 `Space ls`。

### PDF 正反向定位

先成功编译一次，确保 PDF 旁有 `.synctex.gz`。在源码需要查看的位置按 `Space lv`。配置不自动打开 PDF；已打开文档的刷新由 VimTeX/Skim 配合处理。

在 Skim 中按住 **Shift + Command** 点击 PDF 文字，发起反向定位。TeX 文件打开时，Vim 自动注册本会话的远程服务器；无需自己指定服务器名称。回调会寻找拥有该项目的 Vim 会话；必须保留原 Vim 会话运行。返回源码与自动把某个终端窗口置前是两个行为，当前没有增加终端前台焦点脚本。

Skim 设置 → 同步（Sync）中的编辑器设置为 Custom：

- Command：`<vim-executable>`
- Arguments：`-v --not-a-term -T dumb -c "VimtexInverseSearch %line '%file'"`

换机器时将 `<vim-executable>` 替换为 `command -v vim` 的结果，并核对 `+clientserver` 支持。可用 `:echo v:servername` 查看当前服务名，`:VimtexInfo` 查看项目、编译和预览信息。

### 版本、验收与回退

VimTeX 固定 **v2.15**，当前共 17 个插件。禁用其默认快捷键、补全、缩进和语法覆盖，Texlab 继续负责语言服务；F2 与其他语言配置保持原样。

临时带空格路径的多文件项目已生成 PDF 和 SyncTeX，项目 latexmkrc 输出目录生效。Skim 配置已写入并回读；通过其相同反向搜索命令，实际 Vim 已定位到正确子文件第 2 行。已调用正式 `VimtexView` 正向入口，无 Vim 错误。**Skim 的鼠标点击、PDF 高亮位置和窗口焦点尚未做视觉验收：本轮界面工具连续超时。** 不将命令成功当作 GUI 验收。

原配置、旧构建器和 Skim 偏好备份在一次性本地备份目录中，系统可能清理。回退仅恢复本轮 `.vimrc`、`latex-build.vim` 和文档差异；Skim 仅恢复 `SKTeXEditorPreset`、`SKTeXEditorCommand`、`SKTeXEditorArguments` 三项旧值（原先无显式值则删除这三个覆盖项），不要导入完整旧偏好覆盖后续设置。

参考：[VimTeX 官方文档](https://github.com/lervag/vimtex/blob/v2.15/doc/vimtex.txt)。
