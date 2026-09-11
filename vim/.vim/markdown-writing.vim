" Window-local Markdown display helpers. No buffer text is changed.
let s:options = ['number', 'relativenumber', 'cursorline', 'wrap', 'linebreak', 'conceallevel', 'concealcursor']
function! s:Snapshot() abort
  let result = {}
  for option in s:options
    let result[option] = eval('&l:' . option)
  endfor
  return result
endfunction
function! s:Restore() abort
  if exists('w:markdown_display')
    for [option, value] in items(w:markdown_display.before)
      call setwinvar(0, '&' . option, value)
    endfor
    unlet w:markdown_display
  endif
endfunction
function! s:CheckWindow() abort
  if exists('w:markdown_display') && (w:markdown_display.window != win_getid() || w:markdown_display.buffer != bufnr('%') || &filetype !=# 'markdown')
    call s:Restore()
  endif
endfunction
function! s:LeaveBuffer() abort
  if exists('w:markdown_display')
    let w:markdown_pending = {'state': deepcopy(w:markdown_display), 'options': s:Snapshot()}
    call s:Restore()
  endif
endfunction
function! s:LeaveWindow() abort
  if exists('w:markdown_pending')
    let w:markdown_display = w:markdown_pending.state
    for [option, value] in items(w:markdown_pending.options)
      call setwinvar(0, '&' . option, value)
    endfor
    unlet w:markdown_pending
  endif
endfunction
function! s:NewWindow() abort
  let previous = getwinvar(winnr('#'), 'markdown_display', {})
  if !empty(previous) && !exists('w:markdown_display')
    let w:markdown_display = deepcopy(previous)
  endif
  call s:CheckWindow()
endfunction
function! s:State() abort
  call s:CheckWindow()
  if !exists('w:markdown_display')
    let w:markdown_display = {'window': win_getid(), 'buffer': bufnr('%'), 'before': s:Snapshot(), 'focus': 0}
  endif
endfunction
function! MarkdownFocusToggle() abort
  if &filetype !=# 'markdown' | return | endif
  call s:State()
  if w:markdown_display.focus
    for [option, value] in items(w:markdown_display.focus_before)
      call setwinvar(0, '&' . option, value)
    endfor
    let w:markdown_display.focus = 0
    unlet w:markdown_display
  else
    let w:markdown_display.before = s:Snapshot()
    let w:markdown_display.focus_before = copy(w:markdown_display.before)
    let w:markdown_display.focus = 1
    let w:markdown_display.source_level = 2
    setlocal nonumber norelativenumber nocursorline wrap linebreak conceallevel=2 concealcursor=
  endif
endfunction
function! MarkdownSourceToggle() abort
  if &filetype !=# 'markdown' | return | endif
  call s:State()
  if &l:conceallevel
    let w:markdown_display.source_level = &l:conceallevel
    setlocal conceallevel=0
  else
    let &l:conceallevel = get(w:markdown_display, 'source_level', 2)
  endif
endfunction
function! MarkdownOutline() abort
  if &filetype !=# 'markdown' | return | endif
  if exists(':Toc') == 2
    Toc
  else
    echohl WarningMsg | echomsg 'Markdown: vim-markdown :Toc is unavailable.' | echohl None
  endif
endfunction
function! s:Setup() abort
  call s:CheckWindow()
  if &filetype ==# 'markdown'
    nnoremap <buffer> <nowait> <silent> <leader> :<C-u>WhichKey '<Space>'<CR>
    nnoremap <buffer> <silent> <leader>mf :<C-u>MarkdownFocusToggle<CR>
    nnoremap <buffer> <silent> <leader>mc :<C-u>MarkdownSourceToggle<CR>
    nnoremap <buffer> <silent> <leader>mg :<C-u>MarkdownGlowPreview<CR>
    nnoremap <buffer> <silent> <leader>mw :<C-u>setlocal spell!<CR>
    nnoremap <buffer> <silent> <leader>mp :<C-u>MarkdownPreview<CR>
    nnoremap <buffer> <silent> <leader>ms :<C-u>MarkdownPreviewStop<CR>
    nnoremap <buffer> <silent> <leader>mt :<C-u>MarkdownOutline<CR>
    nnoremap <buffer> <silent> <leader>m :<C-u>WhichKey! b:markdown_writing_menu<CR>
    let b:markdown_writing_menu = {'w': [':setlocal spell!', 'spell check'], 'f': [':MarkdownFocusToggle', 'focus'], 'c': [':MarkdownSourceToggle', 'source markers'], 'g': [':MarkdownGlowPreview', 'glow terminal preview'], 't': [':MarkdownOutline', 'outline'], 'p': [':MarkdownPreview', 'browser preview'], 's': [':MarkdownPreviewStop', 'stop preview']}
  elseif exists('b:markdown_writing_menu')
    for key in ['', 'm', 'mf', 'mc', 'mg', 'mt', 'mp', 'ms', 'mw']
      let mapping = maparg(' ' . key, 'n', 0, 1)
      if get(mapping, 'buffer', 0) && get(mapping, 'rhs', '') =~# 'Markdown\|markdown_writing_menu\|WhichKey\|setlocal spell!' 
        execute 'nunmap <buffer> <leader>' . key
      endif
    endfor
    unlet b:markdown_writing_menu
  endif
endfunction
command! MarkdownFocusToggle call MarkdownFocusToggle()
command! MarkdownSourceToggle call MarkdownSourceToggle()
command! MarkdownOutline call MarkdownOutline()
augroup markdown_writing
  autocmd!
  autocmd FileType * call s:Setup()
  autocmd WinNew * call s:NewWindow()
  autocmd BufLeave * call s:LeaveBuffer()
  autocmd WinLeave * call s:LeaveWindow()
  autocmd BufEnter * unlet! w:markdown_pending
  autocmd BufWinEnter,WinEnter * call s:CheckWindow()
augroup END
