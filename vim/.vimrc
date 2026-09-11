let mapleader=" "
let NERDTreeShowHidden=1

" vim-floaterm config
let g:floaterm_keymap_new    = '<F7>'
let g:floaterm_keymap_prev   = '<F8>'
let g:floaterm_keymap_next   = '<F9>'
let g:floaterm_keymap_toggle = '<F12>'

" snippet config
" 触发键
let g:UltiSnipsExpandTrigger = '<tab>'
" 跳转到下一个占位符
let g:UltiSnipsJumpForwardTrigger = '<tab>'
" 跳转到上一个占位符
let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'
" snippet 目录
let g:UltiSnipsSnippetDirectories = ['~/.vim/UltiSnips', 'UltiSnips', fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/.vim/writing-snippets']

" 编辑当前文件类型的 snippets
":UltiSnipsEdit

syntax enable
set background=dark
set t_Co=256

set number
set relativenumber
set ruler
set showcmd
set cursorline
set showmatch
set wildmenu
set autoindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set hidden

" --- 通用编辑体验增强（低风险，不改动既有键位习惯） ------------------------
set clipboard=unnamed     " 与系统剪贴板互通（此 Vim 已 +clipboard）
set backspace=indent,eol,start  " 退格可越过缩进/换行/插入起点
set scrolloff=5 sidescrolloff=8  " 滚动时上下/左右保留余量
set splitright splitbelow   " 新分屏默认开在右侧/下方
set signcolumn=number    " 诊断符号并入行号列，既不抖动也不多占一列
set pumheight=12         " 限制补全弹窗高度
set completeopt=menuone,noinsert,noselect  " CoC：始终显示菜单，不自动插入/选中
set updatetime=300       " 诊断与悬浮文档刷新更快（默认 4000ms）
set autoread             " 文件在外部被改动时自动重读
set noautowrite          " 仅显式保存或预览/构建入口保存当前文件
set diffopt+=vertical    " diff 默认垂直对比
set display+=lastline    " 末行被截断时尽量显示
set shortmess+=c         " 避免插入模式下多余的补全提示
" 双击 Esc 清搜索高亮
nnoremap <silent> <Esc><Esc> :<C-u>nohlsearch<CR>
" 禁用易误触的 Ex 模式
nnoremap Q <nop>

" Persistent undo stays outside project repositories.
let s:cache_root = empty($XDG_CACHE_HOME) ? expand('~/.cache') : $XDG_CACHE_HOME
let s:undo_dir = s:cache_root . '/vim/undo'
if !isdirectory(s:undo_dir)
  call mkdir(s:undo_dir, 'p', 0700)
endif
let &undodir = s:undo_dir . '//'
set undofile

augroup vim_local_editing
  autocmd!
  autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4 tabstop=4
  " 重开文件时跳回上次退出前的光标位置（commit 等临时缓冲除外）
  autocmd BufReadPost *
        \ if line("'\"") >= 1 && line("'\"") <= line("$") && &filetype !~# 'commit' |
        \   execute "normal! g`\"zv" |
        \ endif
augroup END

" --- Markdown: vim-markdown + glow preview ---------------------------------
" https://github.com/preservim/vim-markdown
let g:vim_markdown_folding_disabled = 1   " 默认不折叠
let g:vim_markdown_frontmatter = 1        " 高亮 YAML frontmatter
let g:vim_markdown_strikethrough = 1      " ~~删除线~~ 高亮
let g:vim_markdown_conceal = 1            " 隐藏 ** []() 等标记符号
let g:vim_markdown_conceal_code_blocks = 0

" 终端 glow 预览：保存后用 glow -p 在 floaterm 浮窗渲染；! 走真正 shell 以支持含空格路径，
" ; exit 让 glow 退出后 shell 一并结束，配合 floaterm autoclose 自动关窗。
command! MarkdownGlowPreview
      \ w<Bar>execute 'FloatermNew! glow -p ' . shellescape(expand('%:p')) . '; exit'

augroup vim_local_markdown
  autocmd!
  " 英文拼写检查（仅高亮提示，不改正文）
  autocmd FileType markdown setlocal nospell spelllang=en_us
  " <leader>gm: 保存并在 floaterm 浮窗中用 glow 预览当前文件
  autocmd FileType markdown nnoremap <buffer> <silent> <leader>gm
        \ :<C-u>MarkdownGlowPreview<CR>
augroup END

" Formatting is explicit; missing formatters must not rewrite whitespace.
let g:autoformat_verbosemode = 1
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0
let g:autoformat_remove_trailing_spaces = 0
filetype plugin indent on
colorscheme atom-dark
" VimTeX build/view only; keep CoC completion and existing editing keys.
let g:vimtex_mappings_enabled = 0
let g:vimtex_complete_enabled = 0
let g:vimtex_indent_enabled = 0
let g:vimtex_syntax_enabled = 0
let g:vimtex_view_method = 'skim'
let g:vimtex_view_automatic = 0
let g:vimtex_compiler_latexmk = {'continuous': 0}
let g:vimtex_compiler_latexmk_engines = {'_': ''}
augroup vim_local_tex_server
  autocmd!
  autocmd FileType tex if empty(v:servername) | call remote_startserver('VIMTEX' . getpid()) | endif
augroup END
" Manual, loopback-only browser preview; one shared preview tab per session.
let g:mkdp_browser = 'Firefox'
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 0
let g:mkdp_refresh_slow = 0
let g:mkdp_open_to_the_world = 0
let g:mkdp_combine_preview = 1
let g:mkdp_combine_preview_auto_refresh = 1
call plug#begin()
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'mhinz/vim-startify'
Plug 'ryanoasis/vim-devicons'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'vim-autoformat/vim-autoformat'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'lervag/vimtex', {'tag': 'v2.15'}
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'liuchengxu/vim-which-key'
Plug 'jiangmiao/auto-pairs'
Plug 'mg979/vim-visual-multi'
Plug 'tpope/vim-surround'
Plug 'voldikss/vim-floaterm'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'  " 预定义 snippets 集合
Plug 'preservim/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', {'commit': 'a923f5fc5ba36a3b17e289dc35dc17f66d0548ee', 'do': 'cd app && npm install --omit=dev --ignore-scripts --no-audit --no-fund'}
call plug#end()
map <F3> :NERDTreeToggle<CR>

set timeoutlen=500
nnoremap <nowait> <silent> <leader> :<c-u>WhichKey '<Space>'<CR>
nnoremap <C-p> :Files<CR>
nnoremap <C-f> :Rg<CR>
nnoremap <C-a> :Buffers<CR>
inoremap <expr> <cr> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
noremap <F2> :Autoformat<CR>

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> <leader>rn <Plug>(coc-rename)
nmap <silent> <leader>ca <Plug>(coc-codeaction-cursor)
nnoremap <silent> <leader>d :<C-u>CocList diagnostics<CR>
nnoremap <silent> <leader>s :<C-u>CocList outline<CR>

function! s:ShowDocumentation() abort
  if coc#rpc#ready() && CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    " Execute native K without remapping; respect the filetype's keywordprg.
    normal! K
  endif
endfunction
nnoremap <silent> K :<C-u>call <SID>ShowDocumentation()<CR>

" Manual LaTeX builds; resolve the managed vimrc symlink to find the module.
execute 'source ' . fnameescape(fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/.vim/latex-build.vim')
let g:which_key_map = get(g:, 'which_key_map', {})
let g:which_key_map.l = get(g:which_key_map, 'l', {'name': '+latex'})
let g:which_key_map.l.b = 'build (latexmk)'
let g:which_key_map.l.v = 'view PDF (Skim)'
let g:which_key_map.l.s = 'stop build'
let g:which_key_map.l.o = 'build output'
let g:which_key_map.d = 'diagnostics'
let g:which_key_map.s = 'document symbols'
let g:which_key_map.r = {'name': '+refactor', 'n': 'rename'}
let g:which_key_map.c = {'name': '+code', 'a': 'code action'}
let g:which_key_map.g = {'name': '+preview', 'm': 'glow (Markdown)'}
call which_key#register('<Space>', 'g:which_key_map')

" Markdown writing display and navigation, loaded from the managed repository.
execute 'source ' . fnameescape(fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/.vim/markdown-writing.vim')
execute 'source ' . fnameescape(fnamemodify(resolve(expand('<sfile>:p')), ':h') . '/.vim/marp.vim')
