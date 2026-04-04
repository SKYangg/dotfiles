# vim 模块

> 面包屑：[dotfiles](../CLAUDE.md) > vim

## 职责

Vim 编辑器配置，基于 vim-plug 管理插件，提供 IDE 级编辑体验。

## 文件清单

| 文��� | symlink 目标 | 用途 |
|------|-------------|------|
| `.vimrc` | `~/.vimrc` | Vim 主配置 |

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
- **自动格式化**：vim-autoformat（`<F2>`，保存时自动触发）
- **sudo 写入**：`:w!!` 别名

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

- 工具：`vim`（8.0+），各语言格式化工具（供 autoformat 调用）
- 插件管理器：vim-plug（需手动安装至 `~/.vim/autoload/plug.vim`）
- coc.nvim 需要 Node.js

## 修改指南

- 修改 `.vimrc` 后在 Vim 内执行 `:PlugInstall` / `:PlugUpdate` 同步插件
- coc 插件通过 `:CocInstall coc-<name>` 安装，配置在 `:CocConfig`
- Snippet 自定义文件放在 `~/.vim/UltiSnips/<filetype>.snippets`
