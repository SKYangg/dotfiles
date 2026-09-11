" Run with vim -Nu NONE -i NONE -n -es -S this-file.
set nocompatible hidden
let mapleader=' '
let root=expand('<sfile>:p:h:h')
execute 'source '.fnameescape(root.'/.vim/markdown-writing.vim')
execute 'source '.fnameescape(root.'/.vim/marp.vim')
let work=tempname()
call mkdir(work)
let fake=work.'/fake-marp'
call writefile(['#!/usr/bin/env python3', 'import sys,time,pathlib', 'p=pathlib.Path(sys.argv[sys.argv.index("-o")+1])', 'p.write_text("PDF fixture")', 'print("started",flush=True)', 'time.sleep(0.3)', 'print("finished",flush=True)'],fake)
call setfperm(fake,'rwx------')
function! WaitMarp() abort
  let deadline=reltime()
  while !empty(filter(job_info(), 'job_status(v:val) ==# "run"')) && reltimefloat(reltime(deadline)) < 5
    sleep 20m
  endwhile
  call assert_true(reltimefloat(reltime(deadline)) < 5, 'job deadline')
  sleep 20m
endfunction
let g:marp_command=fake
execute 'edit '.fnameescape(work.'/中文 space.md')
setfiletype markdown
call setline(1,['---','marp: true','---','# Test'])
write
call assert_match('MarpPreview',maparg(' map','n'))
MarpDisable
call assert_equal('',maparg(' map','n'))
MarpAuto
call assert_match('MarpPreview',maparg(' map','n'))
call setline(4,'# Saved by export')
MarpExport
execute 'source '.fnameescape(root.'/.vim/marp.vim')
MarpExport
MarpLog export
let logbuf=bufnr('%')
wincmd p
call WaitMarp()
MarpLog export
call assert_true(index(getline(1,'$'),'finished') >= 0, 'log refresh reads new output')
close
close
let outputs=glob(work.'/.marp-vim-*.pdf',0,1)
call assert_equal(1,len(outputs),'duplicate export refused')
call assert_equal('# Saved by export',readfile(expand('%:p'))[3])
MarpExport
call WaitMarp()
call assert_equal(2,len(glob(work.'/.marp-vim-*.pdf',0,1)),'unique output')
call assert_equal(['PDF fixture'],readfile(outputs[0]),'old output intact')
" Delayed output from an unrelated/old channel must not enter the current log.
let stale=job_start(['sh','-c','exit 0'])
call WaitMarp()
let sid=filter(getscriptinfo(), 'v:val.name =~# "/marp.vim$"')[0].sid
call call(function('<SNR>'.sid.'_Output'), ['export',job_getchannel(stale),'STALE OUTPUT'])
MarpLog export
call assert_equal(-1,index(getline(1,'$'),'STALE OUTPUT'))
close
" Asynchronous process failure removes only this run's empty reserved output.
call writefile(['#!/usr/bin/env python3','import sys','print("intentional failure",file=sys.stderr)','sys.exit(1)'],fake)
let count_before=len(glob(work.'/.marp-vim-*.pdf',0,1))
MarpExport
call WaitMarp()
call assert_equal(count_before,len(glob(work.'/.marp-vim-*.pdf',0,1)),'failed empty output removed')
setfiletype python
setlocal filetype=python
call assert_equal('',maparg(' map','n'))
if !empty(v:errors)
 for error in v:errors | echomsg error | endfor
 cquit
endif
qa!
