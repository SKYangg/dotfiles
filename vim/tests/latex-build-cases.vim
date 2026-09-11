" Regression cases for the VimTeX-backed LaTeX build wrapper (vim/.vim/latex-build.vim).
" Sourced by run-latex-build-tests.sh inside a throwaway workspace. Never edits
" the repository or any real project. Results are written as TSV lines.
"
" Environment contract:
"   VIM_LATEX_TEST_WORKSPACE  fixture root (contains "paper with spaces", ...)
"   VIM_LATEX_TEST_RESULTS    file to write "STATUS<TAB>name<TAB>detail" lines

set nomore
set noswapfile
set shortmess+=atI
set cmdheight=5
set nobackup
set nowritebackup

let s:ws = $VIM_LATEX_TEST_WORKSPACE
let s:results = $VIM_LATEX_TEST_RESULTS
let s:lines = []

function! s:record(status, name, detail) abort
  call add(s:lines, a:status . "\t" . a:name . "\t" . substitute(a:detail, '[\r\n\t]', ' ', 'g'))
endfunction

function! s:check(name, cond, detail) abort
  call s:record(a:cond ? 'PASS' : 'FAIL', a:name, a:detail)
  return a:cond
endfunction

function! s:flush() abort
  call writefile(s:lines, s:results)
endfunction

" Poll an expression until it is true or the limit (seconds) elapses.
function! s:wait_until(expr, limit) abort
  let l:start = reltime()
  while reltimefloat(reltime(l:start)) < a:limit
    if eval(a:expr) | return 1 | endif
    sleep 100m
  endwhile
  return eval(a:expr)
endfunction

function! s:wait_build_done(limit) abort
  return s:wait_until('!b:vimtex.compiler.is_running()', a:limit)
endfunction

function! s:paper(rel) abort
  return s:ws . '/paper with spaces' . (empty(a:rel) ? '' : '/' . a:rel)
endfunction

function! s:open(path) abort
  execute 'edit! ' . fnameescape(a:path)
endfunction

" ---------------------------------------------------------------------------
" Preflight: the wrapper, VimTeX and the "do not steal the screen" settings.
" ---------------------------------------------------------------------------
call s:check('preflight/wrapper-loaded', exists('*LatexBuildStart'),
      \ 'LatexBuildStart defined')
call s:check('preflight/commands', exists(':LatexBuild') == 2 && exists(':LatexBuildLog') == 2,
      \ 'LatexBuild=' . exists(':LatexBuild') . ' LatexBuildLog=' . exists(':LatexBuildLog'))
call s:check('preflight/vimtex-loaded', exists('*vimtex#init'),
      \ 'vimtex#init available (buffer commands appear on tex buffers)')
" The suite must never pop a PDF window into the user's face.
call s:check('preflight/no-auto-view', get(g:, 'vimtex_view_automatic', 1) == 0,
      \ 'g:vimtex_view_automatic=' . string(get(g:, 'vimtex_view_automatic', '<unset>')))
call s:check('preflight/single-shot-build',
      \ get(get(g:, 'vimtex_compiler_latexmk', {}), 'continuous', 1) == 0,
      \ 'continuous=' . string(get(get(g:, 'vimtex_compiler_latexmk', {}), 'continuous', '<unset>')))
call s:check('preflight/clientserver', has('clientserver'), 'has(clientserver)')

" ---------------------------------------------------------------------------
" Key mappings: Space lb / lv / ls / lo
" ---------------------------------------------------------------------------
for [s:lhs, s:want] in [[' lb', 'LatexBuild'], [' lv', 'VimtexView'],
      \ [' ls', 'VimtexStop'], [' lo', 'VimtexCompileOutput']]
  let s:rhs = maparg(s:lhs, 'n')
  call s:check('mapping/<Space>' . trim(s:lhs), s:rhs =~# s:want,
        \ 'rhs=' . (empty(s:rhs) ? '<none>' : s:rhs))
endfor

" ---------------------------------------------------------------------------
" Main-file identification from a subfile in a path containing spaces.
" ---------------------------------------------------------------------------
call s:open(s:paper('sections/intro.tex'))
call s:check('root/filetype', &filetype ==# 'tex', 'filetype=' . &filetype)
call s:check('root/space-in-path', expand('%:p') =~# ' ', expand('%:p'))
" Buffer-local VimTeX commands only exist once a TeX buffer is initialised.
call s:check('preflight/vimtex-buffer-commands',
      \ exists(':VimtexCompile') == 2 && exists(':VimtexStop') == 2,
      \ 'VimtexCompile=' . exists(':VimtexCompile') . ' VimtexStop=' . exists(':VimtexStop'))

let s:main = resolve(s:paper('main.tex'))
if s:check('root/vimtex-attached', exists('b:vimtex'), 'b:vimtex present')
  call s:check('root/main-from-subfile', resolve(b:vimtex.tex) ==# s:main,
        \ 'resolved=' . resolve(b:vimtex.tex))
endif

" ---------------------------------------------------------------------------
" Baseline build from the subfile + .latexmkrc honoured (custom $out_dir).
" ---------------------------------------------------------------------------
let s:pdf = s:paper('build output/main.pdf')
let s:started = LatexBuildStart()
call s:check('build/start-from-subfile', s:started == 1, 'LatexBuildStart=' . s:started)

if s:started == 1
  let s:done = s:wait_build_done(120)
  call s:check('build/completes', s:done, s:done ? 'finished' : 'TIMEOUT after 120s')
  sleep 500m
  call s:check('build/pdf-in-latexmkrc-outdir', filereadable(s:pdf), 'pdf=' . s:pdf)
  call s:check('build/log-in-latexmkrc-outdir',
        \ filereadable(s:paper('build output/main.log')), 'log in "build output"')
  " Default latexmk behaviour would drop main.pdf next to main.tex; absence there
  " is direct evidence the project .latexmkrc $out_dir took effect.
  call s:check('build/no-pdf-beside-source', !filereadable(s:paper('main.pdf')),
        \ 'no stray ' . s:paper('main.pdf'))
  let s:qf = filter(getqflist(), {_, v -> get(v, 'valid', 0)})
  call s:check('build/clean-quickfix', empty(s:qf), 'valid qf entries=' . len(s:qf))
endif
let s:baseline_mtime = getftime(s:pdf)

" ---------------------------------------------------------------------------
" A real LaTeX error must land on the right file and line.
" ---------------------------------------------------------------------------
let s:broken = [
      \ '% !TeX root = ../main.tex',
      \ 'Intro line two.',
      \ '\thiscommanddoesnotexist',
      \ 'Intro line four.',
      \ ]
call writefile(s:broken, s:paper('sections/intro.tex'))
call s:open(s:paper('sections/intro.tex'))

let s:started = LatexBuildStart()
call s:check('error/build-starts', s:started == 1, 'LatexBuildStart=' . s:started)
if s:started == 1
  let s:done = s:wait_build_done(120)
  call s:check('error/build-finishes', s:done, s:done ? 'finished' : 'TIMEOUT after 120s')
  sleep 500m
  let s:qf = filter(getqflist(), {_, v -> get(v, 'valid', 0)})
  call s:check('error/quickfix-populated', !empty(s:qf), 'valid qf entries=' . len(s:qf))
  let s:hit = filter(copy(s:qf), {_, v ->
        \ bufname(v.bufnr) =~# 'intro\.tex$' && v.lnum == 3})
  call s:check('error/points-at-intro-line-3', !empty(s:hit),
        \ empty(s:qf) ? 'no entries'
        \   : 'first=' . bufname(s:qf[0].bufnr) . ':' . s:qf[0].lnum . ' text=' . s:qf[0].text)
endif

" ---------------------------------------------------------------------------
" Fixing the source must produce a clean rebuild.
" ---------------------------------------------------------------------------
sleep 1200m
let s:fixed = [
      \ '% !TeX root = ../main.tex',
      \ 'Intro line two.',
      \ 'Now a valid line.',
      \ 'Intro line four.',
      \ ]
call writefile(s:fixed, s:paper('sections/intro.tex'))
call s:open(s:paper('sections/intro.tex'))

let s:started = LatexBuildStart()
call s:check('fix/build-starts', s:started == 1, 'LatexBuildStart=' . s:started)
if s:started == 1
  let s:done = s:wait_build_done(120)
  call s:check('fix/build-finishes', s:done, s:done ? 'finished' : 'TIMEOUT after 120s')
  sleep 500m
  let s:qf = filter(getqflist(), {_, v -> get(v, 'valid', 0)})
  call s:check('fix/quickfix-cleared', empty(s:qf),
        \ empty(s:qf) ? 'no valid entries'
        \   : 'still ' . len(s:qf) . ' e.g. ' . bufname(s:qf[0].bufnr) . ':' . s:qf[0].lnum)
  call s:check('fix/pdf-regenerated', getftime(s:pdf) > s:baseline_mtime,
        \ 'baseline=' . s:baseline_mtime . ' now=' . getftime(s:pdf))
endif

" ---------------------------------------------------------------------------
" Save guard: another modified TeX buffer blocks the build.
" ---------------------------------------------------------------------------
call s:open(s:paper('sections/appendix.tex'))
call setline(1, '% dirty buffer, intentionally unsaved')
call s:check('guard/appendix-modified', &modified, 'modified=' . &modified)
call s:open(s:paper('sections/intro.tex'))
let s:started = LatexBuildStart()
call s:check('guard/blocks-on-unsaved-sibling', s:started == 0,
      \ 'LatexBuildStart=' . s:started)
" Drop the dirty state so it cannot leak into later cases.
let s:appendix_nr = bufnr(s:paper('sections/appendix.tex'))
if s:appendix_nr > 0
  execute 'bwipeout! ' . s:appendix_nr
endif

" ---------------------------------------------------------------------------
" No main document -> explicit refusal, no guessing.
" ---------------------------------------------------------------------------
call s:open(s:ws . '/orphan/orphan.tex')
let s:started = LatexBuildStart()
call s:check('guard/refuses-without-main', s:started == 0, 'LatexBuildStart=' . s:started)

" ---------------------------------------------------------------------------
" Repeat-trigger protection and stopping a build (slow fixture).
" ---------------------------------------------------------------------------
call s:open(s:ws . '/slow build/main.tex')
if s:check('stop/vimtex-attached', exists('b:vimtex'), 'b:vimtex present')
  let s:started = LatexBuildStart()
  call s:check('stop/build-starts', s:started == 1, 'LatexBuildStart=' . s:started)
  if s:started == 1
    let s:running = s:wait_until('b:vimtex.compiler.is_running()', 15)
    call s:check('stop/build-is-running', s:running,
          \ s:running ? 'compiler running' : 'never observed running within 15s')
    if s:running
      let s:second = LatexBuildStart()
      call s:check('repeat/second-trigger-refused', s:second == 0,
            \ 'second LatexBuildStart=' . s:second)
      call s:check('repeat/still-single-build', b:vimtex.compiler.is_running(),
            \ 'original build still running')
    endif
    silent! VimtexStop
    let s:stopped = s:wait_until('!b:vimtex.compiler.is_running()', 20)
    call s:check('stop/vimtex-stop-halts-build', s:stopped,
          \ s:stopped ? 'compiler stopped' : 'STILL RUNNING after 20s')
  endif
endif

call s:flush()
qa!
