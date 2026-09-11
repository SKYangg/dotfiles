" Marp CLI integration. Explicit commands only; no implicit project config.
let s:jobs = get(s:, 'jobs', {})
function! s:Enabled() abort
  if &filetype !=# 'markdown' | return 0 | endif
  if exists('b:marp_manual') | return b:marp_manual | endif
  if getline(1) !=# '---' | return 0 | endif
  let enabled = 0
  for line in getline(2, min([line('$'), 100]))
    if line =~# '^---\s*$' | return enabled | endif
    if line =~# '^marp:\s*true\s*$' | let enabled = 1 | endif
  endfor
  return 0
endfunction
function! s:Running(kind) abort
  return has_key(s:jobs, a:kind) && job_status(s:jobs[a:kind].job) ==# 'run'
endfunction
function! s:Exit(kind, job, status) abort
  if !has_key(s:jobs, a:kind) || s:jobs[a:kind].job != a:job | return | endif
  let item = s:jobs[a:kind]
  let item.status = a:status
  if has_key(item, 'appdata') | call delete(item.appdata, 'rf') | endif
  if item.stopping | return | endif
  if a:status == 0 && getfsize(item.output) > 0
    echomsg 'Marp ' . a:kind . ' completed: ' . item.output . ' (check rendering and log warnings)'
  else
    if getfsize(item.output) == 0 | call delete(item.output) | endif
    echohl WarningMsg | echomsg 'Marp failed; :MarpLog ' . a:kind | echohl None
  endif
endfunction
function! s:Output(kind, channel, line) abort
  if !has_key(s:jobs, a:kind) | return | endif
  let item = s:jobs[a:kind]
  if job_getchannel(item.job) != a:channel | return | endif
  call writefile([a:line], item.log, 'a')
  if a:kind ==# 'preview' && !item.opened && getfsize(item.output) > 0
    let item.opened = 1
    call job_start(['open', '-a', 'Firefox', item.output])
  endif
endfunction
function! MarpStart(kind) abort
  if !s:Enabled() | echoerr 'Marp: use front matter marp: true or :MarpEnable' | return | endif
  if s:Running(a:kind)
    echomsg 'Marp ' . a:kind . ' already running; stop preview before switching decks.' | return
  endif
  let executable = expand(get(g:, 'marp_command', '~/.local/share/vim-marp/node_modules/.bin/marp'))
  if !executable(executable) || !executable('python3')
    echoerr 'Marp: CLI or python3 missing; see maintenance instructions' | return
  endif
  if empty(expand('%:p')) || &buftype !=# '' | echoerr 'Marp: name the file first' | return | endif
  try
    update
  catch
    echoerr 'Marp: save failed; not started' | return
  endtry
  let source = expand('%:p')
  " mkstemp reserves a unique owned file atomically; CLI can replace only that file.
  let code = 'import os,sys,tempfile; fd,p=tempfile.mkstemp(prefix=".marp-vim-",suffix=sys.argv[2],dir=sys.argv[1]); os.close(fd); print(p)'
  let output = systemlist(['python3', '-c', code, fnamemodify(source, ':h'), a:kind ==# 'preview' ? '.html' : '.pdf'])
  if v:shell_error || empty(output) | echoerr 'Marp: cannot reserve output file' | return | endif
  let item = {'output': output[0], 'log': tempname(), 'stopping': 0, 'status': -1, 'opened': 0}
  let command = [executable, '--no-stdin', '--no-config', source, '-o', item.output]
  if exists('g:marp_config') && !empty(g:marp_config)
    let command = [executable, '--no-stdin', '--config', expand(g:marp_config), source, '-o', item.output]
  endif
  call extend(command, ['--browser', 'firefox', '--browser-path', '/Applications/Firefox.app/Contents/MacOS/firefox'])
  if get(g:, 'marp_allow_local_files', 0) | call add(command, '--allow-local-files') | endif
  call add(command, a:kind ==# 'preview' ? '--watch' : '--pdf')
  let environment = {}
  if a:kind ==# 'export'
    let item.appdata = tempname()
    call mkdir(item.appdata, '', 0700)
    let environment.MOZ_APP_DATA = resolve(item.appdata)
  endif
  let item.job = job_start(command, {'cwd': fnamemodify(source, ':h'), 'env': environment, 'out_cb': function('s:Output', [a:kind]), 'err_cb': function('s:Output', [a:kind]), 'exit_cb': function('s:Exit', [a:kind]), 'stoponexit': 'term'})
  let s:jobs[a:kind] = item
  if job_status(item.job) ==# 'fail'
    if has_key(item, 'appdata') | call delete(item.appdata, 'rf') | endif
    call delete(item.output)
    call writefile(['Marp: process could not start'], item.log)
    echoerr 'Marp: process could not start; see :MarpLog ' . a:kind
    return
  endif
  echomsg 'Marp ' . a:kind . ': ' . item.output
endfunction
function! MarpStop() abort
  if s:Running('preview')
    let s:jobs.preview.stopping = 1
    call job_stop(s:jobs.preview.job)
  endif
endfunction
function! MarpLog(kind) abort
  if !has_key(s:jobs, a:kind) | echomsg 'Marp: no ' . a:kind . ' log yet' | return | endif
  execute 'botright split ' . fnameescape(s:jobs[a:kind].log)
  setlocal buftype=nofile bufhidden=wipe noswapfile modifiable
  silent %delete _
  call setline(1, filereadable(s:jobs[a:kind].log) ? readfile(s:jobs[a:kind].log) : ['No output yet.'])
  setlocal nomodified nomodifiable
endfunction
function! s:Setup() abort
  if exists('b:markdown_writing_menu')
    if s:Enabled()
      let b:markdown_writing_menu.a = {'name': '+marp', 'p': [':MarpPreview', 'preview'], 'e': [':MarpExport', 'PDF'], 's': [':MarpStop', 'stop preview'], 'l': [':MarpLog preview', 'preview log'], 'o': [':MarpLog export', 'export log']}
      for [key, cmd] in items({'p':'MarpPreview', 'e':'MarpExport', 's':'MarpStop', 'l':'MarpLog preview', 'o':'MarpLog export'})
        execute 'nnoremap <buffer> <silent> <leader>ma' . key . ' :<C-u>' . cmd . '<CR>'
      endfor
    elseif has_key(b:markdown_writing_menu, 'a')
      call remove(b:markdown_writing_menu, 'a')
    endif
  endif
  if !s:Enabled()
    for key in ['p','e','s','l','o']
      if get(maparg(' ma'.key, 'n', 0, 1), 'rhs', '') =~# 'Marp'
        execute 'silent! nunmap <buffer> <leader>ma' . key
      endif
    endfor
  endif
endfunction
command! MarpPreview call MarpStart('preview')
command! MarpExport call MarpStart('export')
command! MarpStop call MarpStop()
command! -nargs=1 MarpLog call MarpLog(<q-args>)
command! MarpEnable let b:marp_manual = 1 | call s:Setup()
command! MarpDisable let b:marp_manual = 0 | call s:Setup()
command! MarpAuto unlet! b:marp_manual | call s:Setup()
augroup marp_integration
  autocmd!
  autocmd FileType,BufWritePost * call s:Setup()
augroup END
