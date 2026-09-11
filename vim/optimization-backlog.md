# Vim 优化报告 / 待办

> 状态：**待后续变更**（本报告只记录，不自动执行）
> 环境：纯 Vim 9.2（`/opt/homebrew/bin/vim`，非 Neovim），`+clipboard +terminal +persistent_undo`
> 插件管理：vim-plug；当前 19 个插件
> 约束：最小化、低风险、不改变既有键位习惯；**禁止保存时改写空白**（见 `CLAUDE.md` 约定）
> 最近更新：2026-09

---

## 一、本轮已完成（当前会话为准）

### 1. Markdown 语法高亮
- 新增插件 `preservim/vim-markdown`（已 `:PlugInstall`）。
- 配置：默认不折叠、识别 YAML frontmatter、`~~删除线~~` 高亮、conceal 隐藏标记（代码块不 conceal）。

### 2. glow 终端预览（glow 3.0.0，Homebrew）
- 新增全局命令 `:MarkdownGlowPreview`：保存后 `FloatermNew! glow -p <绝对路径> ; exit`。
- 快捷键：`空格 g m`；并登记进 `空格 m` 菜单的 `g` 项（改了 `.vim/markdown-writing.vim`，含清理名单）。
- 踩坑与最终形态：
  - 闪退 → glow v3 渲染完即退，必须 `glow -p` 停留。
  - `accepts at most 1 arg(s), received 2` → 路径含空格；`FloatermNew` 走 Vim argv 拆分只认双引号，`shellescape()` 单引号被切碎。改 **`FloatermNew!`** 走真正 shell。
  - 退出不自动关窗 → 命令尾加 **`; exit`**，配合 floaterm 默认 `autoclose=1`。

### 3. 通用编辑增强（A 档 + 冲突合并）
A 档新增：
```vim
set scrolloff=5 sidescrolloff=8
set splitright splitbelow
set signcolumn=number
set completeopt=menuone,noinsert,noselect
set updatetime=300
" BufReadPost：重开文件跳回上次光标位置（排除 commit 临时缓冲，带越界保护）
```
与“另一会话”遗留配置冲突，**已按本会话取值合并去重**：
- 冲突项：`sidescrolloff` 取 **8**（非 3）；`signcolumn` 取 **number**（非 yes）。
- 保留对方独有项：`clipboard=unnamed`、`backspace`、`pumheight=12`、`autoread`、`autowrite`、`diffopt+=vertical`、`display+=lastline`、`shortmess+=c`、`双 Esc 清高亮`、`Q 禁用`。
- 删除重复的第二个 `set showcmd`。

### 4. Markdown 写作（B4 / B5）
- `autocmd FileType markdown setlocal spell spelllang=en_us`（仅高亮，不改正文）。
- glow 预览进入 `空格 m` 菜单（见 1.2）。

> 生效方式：全局 `set` / 全局命令 `:source ~/.vimrc` 即可；FileType 的 buffer-local 映射必须 `:qa!` 彻底重开。

---

## 二、待办清单（按价值 / 风险排序）

### 建议直接做（低风险）

| ID | 项目 | 风险 |
|----|------|------|
| P1 | swap / backup 移出项目目录 | 低 |
| P2 | `nnoremap Y y$`（对齐 `C`/`D` 语义） | 低 |
| P3 | 让 `autoread` 真正可靠（`checktime`） | 低 |
| P4 | 内置 `:grep` 改用 ripgrep | 低 |
| P5 | `set confirm`、`jumpoptions+=stack` | 低 |
| P6 | `path+=**` 与 `wildignore` 过滤 | 低 |

### 改变行为，需确认后单独做

| ID | 项目 | 风险 |
|----|------|------|
| P7 | **智能 Tab**：调和 CoC 补全与 UltiSnips（当前最大摩擦） | 中，需实测三场景 |
| P8 | 可视模式粘贴不覆盖无名寄存器 `xnoremap p "_dP` | 低-中（改 `p` 语义） |
| P9 | Markdown 插入模式显示标记符号（`concealcursor`） | 低-中（动 markdown-writing 窗口状态，须跑测试） |
| P10 | Markdown 列表自动续行 / `gq` 折行（B6） | 中（改变打字行为） |

### 观感 / 插件（可选，一向克制）

| ID | 项目 | 风险 |
|----|------|------|
| P11 | `termguicolors`（Ghostty 真彩色，需目测 atom-dark） | 观感变更 |
| P12 | airline powerline 字体（需 patched font，需目测） | 观感变更 |
| P13 | `tpope/vim-fugitive`（将成为第 20 个插件） | 新增插件 |

### 文档债
- `CLAUDE.md` 的“插件列表/主要配置项”停在 17 个插件，**缺** vim-markdown、markdown-preview.nvim、glow 集成，以及本轮通用选项与拼写检查；落地待办时一并更新。

---

## 三、待办的具体建议配置

### P1 swap / backup 归到缓存目录（与 undo 同哲学）
```vim
let s:swap_dir   = s:cache_root . '/vim/swap'
let s:backup_dir = s:cache_root . '/vim/backup'
for d in [s:swap_dir, s:backup_dir]
  if !isdirectory(d) | call mkdir(d, 'p', 0700) | endif
endfor
let &directory = s:swap_dir . '//'
let &backupdir = s:backup_dir . '//'
set backup
" 可选：view 目录与 :mkview 自动恢复（与现有 BufReadPost 二选一，避免重复）
```

### P2
```vim
nnoremap Y y$
```

### P3 autoread 增强（外部改文件，切回自动重载）
```vim
augroup vim_local_autoread
  autocmd!
  autocmd FocusGained,BufEnter,CursorHold,CursorHoldI *
        \ if mode() !~? '[c]' | silent! checktime | endif
augroup END
```
注意：buffer 本身有未保存修改时不会被静默覆盖。

### P4 内置 :grep 走 ripgrep（rg 15.2.0 已装）
```vim
set grepprg=rg\ --vimgrep\ --smart-case
" --vimgrep 输出匹配默认 grepformat '%f:%l:%c:%m'，结果进 quickfix
```

### P5
```vim
set confirm                 " :q 有未保存内容时弹确认而非报错
set jumpoptions+=stack      " Ctrl-O / Ctrl-I 跳栈行为更直观（Vim 8+）
" history 默认通常已足够，不建议为设而设
```

### P6
```vim
set path+=**
set wildignore+=.git/*,node_modules/*,dist/*,build/*,__pycache__/*,*.pyc
```

### P7 智能 Tab（CoC wiki 经典方案；落地后必须实测）
现状：`<Tab>` 被 UltiSnips 独占（展开 + 前跳），CoC 菜单弹出时按 Tab 行为别扭；`<CR>` 已确认补全，保留。
```vim
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ "\<C-r>=UltiSnips#JumpForwards()\<CR>"
function! UltiSnips#JumpForwards()
  if exists('*UltiSnips#JumpForwardsTrigger') && UltiSnips#JumpForwardsTrigger()
    return "\<Plug>(ultisnips_jump_forward)"
  endif
  return "\<TAB>"
endfunction
inoremap <silent><expr> <S-TAB>
      \ coc#pum#visible() ? coc#pum#prev(1) :
      \ "\<C-r>=UltiSnips#JumpBackwards()\<CR>"
function! UltiSnips#JumpBackwards()
  if !exists('*UltiSnips#JumpBackwardsTrigger') || !UltiSnips#JumpBackwardsTrigger()
    return "\<S-TAB>"
  endif
  return "\<Plug>(ultisnips_jump_backward)"
endfunction
```
验收三场景：① 普通补全菜单 Tab 切换、CR 确认；② snippet 展开与 Tab/S-Tab 跳占位符；③ 非 snippet 处 Tab 仍原样缩进。

### P8
```vim
xnoremap p "_dP
```

### P9 Markdown 插入模式显示标记
- 方向：FileType markdown 设 `concealcursor=nc`（normal/command 隐藏，insert/visual 显示 `** []()`）。
- 必须与 `.vim/markdown-writing.vim` 的窗口快照逻辑（已含 `concealcursor`）协同，改完跑 `tests/markdown-writing-cases.vim`。

### P10 Markdown 列表 / 折行（先验证再开）
```vim
autocmd FileType markdown setlocal formatoptions+=r     " 回车续列表标记
" 折行建议只用 gq（不建议加 't' 边打边折）；如需：setlocal textwidth=80
```
具体续行依赖 markdown ftplugin 的 `formatlistpat/comments`，落地时先小步验证。

### P11 / P12 / P13
```vim
set termguicolors                 " P11：先目测，不满意立即撤
let g:airline_powerline_fonts = 1 " P12：需 patched font
Plug 'tpope/vim-fugitive'         " P13：第 20 个插件
```

---

## 四、验证方法（每次变更后）

```bash
# 1) vimrc / 脚本语法（headless，避免 PTY 问题）
vim -u NONE -N -n -es -c 'source /Users/skyang/dotfiles/vim/.vimrc' -c 'qa!' ; echo $?

# 2) Markdown 模块自带测试
cd /Users/skyang/dotfiles/vim
vim -u NONE -N -n -es -S tests/markdown-writing-cases.vim ; echo $?
```
两者均需 `exit=0`。运行时核对：`:set <选项>?`、`:autocmd <组名>`。

## 五、应用方式
- 报编号即可，如「P1 P2 P3」或「P7 单独做」。
- P7/P9/P10 建议各单独一轮，便于回滚。
- 另一会话已异常终止；**以当前会话为准**，落地前确认没有其他 Vim/会话并发写 `.vimrc`。
