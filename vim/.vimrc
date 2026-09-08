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
let g:UltiSnipsSnippetDirectories = ['~/.vim/UltiSnips', 'UltiSnips']

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
call plug#end()
map <F3> :NERDTreeToggle<CR>

set timeoutlen=500
nnoremap <silent> <leader> :<c-u>WhichKey '<Space>'<CR>
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
call which_key#register('<Space>', 'g:which_key_map')
