# VimTeX + Skim：编译、正向/反向搜索

> 环境：纯 Vim 9.2（`/opt/homebrew/bin/vim`，`+clientserver`，非 Neovim）、TeX Live 2026、
> vimtex v2.15、Skim（PDF 阅读器）。
> 说明：记录当前实际生效的键位、Skim 配置、反向搜索原理与排障；改配置后以本文“验证”一节为准。

## 1. 快捷键（`<leader>` = 空格）

| 快捷键 | 命令 | 作用 |
|---|---|---|
| `空格 l b` | `:LatexBuild` | 编译：保存 → 主文件/root 校验 → `:VimtexCompile`（单次，非 continuous） |
| `空格 l v` | `:VimtexView` | Skim 打开 PDF 并**正向定位**到光标所在行（SyncTeX） |
| `空格 l s` | `:VimtexStop` | 停止编译 |
| `空格 l o` | `:VimtexCompileOutput` | 查看编译输出/日志 |

对应封装在 `~/.vim/latex-build.vim`；Skim 相关变量在 `~/.vimrc`
（`g:vimtex_view_method='skim'`、`g:vimtex_view_automatic=0`，即不自动弹 PDF，需手动 `lv`）。

## 2. 正向搜索（Vim → Skim）

编译后按 **`空格 l v`**：Skim 打开/切到 PDF，并跳到光标对应页/行。
需要编译时生成 SyncTeX（latexmk 默认 `--synctex` 开启，产物为 `*.synctex.gz`）。

## 3. 反向搜索（Skim → Vim）

在 Skim 的 PDF 中，按住 **`Shift + ⌘` 单击**某行文字，即跳回正在编辑该文件的 Vim 对应源码行：
自动打开/切换到对应窗口与标签页并跳到该行；若需要会先打开该文件。

> macOS 无 `xdotool`，**焦点一般不会自动从 Skim 切回终端**——Vim 内已跳转，`⌘+Tab`
> 或点一下终端即可看到光标。属正常现象。首次触发 Skim 可能弹一次授权框，允许即可。

### 3.1 工作原理

Skim 把行号、文件作为参数执行一条 shell 命令；该命令启动一个临时 Vim，通过
clientserver 向**正在运行的 Vim server** 发送 `vimtex#view#inverse_search(line, file)`，
随后临时进程退出。vimtex 自动枚举所有 server 并匹配当前 VimTeX 工程，无需手填 servername。

### 3.2 三个前提

1. **编辑中的终端 Vim 已启动 server。** `~/.vimrc` 中：
   ```vim
   autocmd FileType tex if empty(v:servername)
         \ | call remote_startserver('VIMTEX' . getpid()) | endif
   ```
   打开任意 `filetype=tex` 的文件即自动起 server（名字 `VIMTEX<pid>`，无需关心）。
   本机实测：Homebrew Vim（`-X11`）在终端下也能跨进程发现 server，**不依赖 X11**。

2. **Skim → Settings → Sync 选 `Custom`**（当前 `defaults read -app Skim` 即如此）：
   - Command：`/opt/homebrew/bin/vim`
   - Arguments：``-v --not-a-term -T dumb -c "VimtexInverseSearch %line '%file'"``
   - 注意变量是 Skim 的 `%line` / `%file`（不是 vimtex 文档通用写法里的 `%l`/`%f`）。

3. **存在 `*.synctex.gz`**：由 latexmk 编译产生。

### 3.3 在编辑用的 Vim 里自检

```vim
:echo v:servername      " 应打印 VIMTEX12345 之类；为空说明该 buffer 不是 tex
:set ft?                " 应为 ft=tex
```

## 4. XeLaTeX 工程要点（含 iCloud 含空格路径）

症状：`空格 l b` 提示用 xetex 或直接失败，常见于 `ctexart` / `fontspec` /
`\setCJKmainfont` 文档被 pdflatex 编译（报 `fontspec requires XeTeX or LuaTeX`）。

根因：`~/.vimrc` 刻意把引擎留空，交由**项目自身 `latexmkrc` 决定**：
```vim
let g:vimtex_compiler_latexmk         = {'continuous': 0}
let g:vimtex_compiler_latexmk_engines = {'_': ''}
```
若项目目录没有 `latexmkrc`，latexmk 回落 pdflatex → 必败。

修复：在**主 TeX 所在目录**放最小 `latexmkrc`（示例：`resume/src/latexmkrc`）：
```perl
# ctexart + fontspec + \setCJKmainfont 必须 XeLaTeX；$pdf_mode=5 = latexmk -xelatex
$pdf_mode = 5;
```
命令行验证（VimTeX 同款：cd 进目录、只传文件名，规避空格路径）：
```bash
cd "<项目>/src"
latexmk -interaction=nonstopmode -synctex=1 -g CV_master.tex
# 期望看到：Rc files read: ./latexmkrc；applying rule 'xelatex'；Output written ...
```

> iCloud 路径含空格无需特殊处理：VimTeX 会 cd 到文件目录只传文件名，与项目 `build.sh` 一致。
> 注意输出位置差异：`空格 l b` 的 PDF 在 `src/`（供 Skim 同步）；`build.sh` 把干净产物放 `outputs/`。

## 5. Skim 其他建议

- Settings → Sync 勾选 **Check for file changes**：编译后 PDF 自动刷新（不影响反向搜索）。
- 若希望编译成功自动弹 PDF，可设 `g:vimtex_view_automatic=1`（当前刻意关闭，保持手动）。

## 6. 排障清单

| 现象 | 检查 |
|---|---|
| `Shift+⌘+点` 无反应 | `:echo v:servername` 非空；Skim 为 Custom 且命令路径正确；`.synctex.gz` 存在 |
| 跳过去但焦点还在 Skim | 正常（无 xdotool）；`⌘+Tab` 回终端 |
| 编译报 fontspec/XeTeX 错 | 项目目录加 `latexmkrc`：`$pdf_mode = 5;` |
| `accepts ... args` / 路径报错 | 确认从文件所在目录编译、文件名本身不含空格 |
| server 列表为空 | 该 buffer `:set ft?` 为 tex；或在 vimrc 用全局兜底 `remote_startserver('VIM')` |
| PDF 不刷新 | Skim 勾选 Check for file changes；确认 PDF 路径与 `:VimtexView` 打开的是同一份 |

跨进程 server 可用性的离线测试（无需进入交互 Vim）：
```bash
( sleep 10 | vim --not-a-term -u NONE -N -n --servername PISRV2 - >/tmp/s.log 2>&1 ) &
sleep 3; vim --serverlist        # 应能看到 PISRV2
```
