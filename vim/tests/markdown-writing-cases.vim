set nocompatible
let mapleader = ' '
execute 'source ' . fnameescape(expand('<sfile>:p:h:h') . '/.vim/markdown-writing.vim')
function! Snapshot() abort
  return [&number, &relativenumber, &cursorline, &wrap, &linebreak, &conceallevel, &concealcursor]
endfunction
new
setfiletype markdown
call setline(1, ['# 标题', '中文长段落以及 [链接](https://example.org) 和 $x^2$。', '```julia', 'x = 1', '```'])
let content = getline(1, '$')
let modified = &modified
for settings in ['number relativenumber cursorline nowrap nolinebreak conceallevel=3 concealcursor=nc', 'nonumber norelativenumber nocursorline wrap linebreak conceallevel=0 concealcursor=']
  execute 'setlocal ' . settings
  let before = Snapshot()
  for iteration in range(2)
    MarkdownFocusToggle
    call assert_equal([0,0,0,1,1,2,''], Snapshot())
    MarkdownSourceToggle
    call assert_equal(0, &conceallevel)
    MarkdownFocusToggle
    call assert_equal(before, Snapshot())
  endfor
endfor
setlocal conceallevel=3
MarkdownSourceToggle
call assert_equal(0, &conceallevel)
MarkdownSourceToggle
call assert_equal(3, &conceallevel)
let before = Snapshot()
MarkdownFocusToggle
let origin = win_getid()
split
call assert_equal(before, Snapshot(), 'new split restores baseline')
call win_gotoid(origin)
call assert_equal(2, &conceallevel, 'original keeps focus')
wincmd p
call win_gotoid(origin)
call assert_equal(0, &number, 'window focus change preserves mode')
MarkdownFocusToggle
call assert_equal(before, Snapshot())
MarkdownFocusToggle
setlocal bufhidden=hide
enew
setfiletype python
call assert_false(exists('w:markdown_display'))
call assert_equal('', maparg(' mf','n'))
buffer #
call assert_equal(before, Snapshot(), 'buffer return restores baseline')
MarkdownFocusToggle
setfiletype python
" setfiletype does not replace an existing type; explicit change does.
setlocal filetype=python
call assert_equal(before, Snapshot(), 'filetype change restores baseline')
call assert_equal('', maparg(' mf','n'))
setlocal filetype=markdown
call assert_match('MarkdownFocusToggle', maparg(' mf','n'))
if exists(':Toc') == 2
  MarkdownOutline
  call assert_true(&buftype ==# 'quickfix', 'real Toc opens directory')
  close
endif
if exists(':WhichKey') == 2
  let prior = &conceallevel
  call feedkeys('c', 't')
  WhichKey! b:markdown_writing_menu
  call assert_notequal(prior, &conceallevel, 'real menu executes source action')
  MarkdownSourceToggle
endif
command! -buffer Toc let b:outline_called = 1
MarkdownOutline
call assert_equal(1, b:outline_called)
call assert_equal(content, getline(1,'$'))
call assert_equal(modified, &modified)
if !empty(v:errors)
  for error in v:errors | echomsg error | endfor
  cquit
endif
qa!
