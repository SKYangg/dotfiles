" VimTeX owns compilation, logging and viewing; this wrapper preserves save/root guards.
if exists('g:loaded_local_latex_build') | finish | endif
let g:loaded_local_latex_build = 1
function! s:Root() abort
  let file = resolve(expand('%:p'))
  if empty(file) || &buftype !=# '' || index(['tex', 'plaintex'], &filetype) < 0
    throw 'Open a named TeX file first.'
  endif
  let seen = []
  for depth in range(16)
    if index(seen, file) >= 0 | throw 'Cycle in TeX root directives.' | endif
    call add(seen, file)
    let nr = bufnr(file)
    if nr > 0 && bufloaded(nr)
      let lines = getbufline(nr, 1, '$')
    elseif filereadable(file)
      let lines = readfile(file)
    else
      throw 'TeX root does not exist: ' . file
    endif
    let roots = []
    for line in lines[:49]
      let m = matchlist(line, '\c^\s*%\s*!\s*TeX\s\+root\s*=\s*\(.\{-}\)\s*$')
      if !empty(m)
        let root = trim(m[1])
        if root =~# '^".*"$' || root =~# "^'.*'$" | let root = root[1:-2] | endif
        if empty(root) | throw 'Empty TeX root directive.' | endif
        call add(roots, resolve(fnamemodify(root =~# '^/' ? root : fnamemodify(file, ':h') . '/' . root, ':p')))
      endif
    endfor
    call uniq(sort(roots))
    if len(roots) > 1 | throw 'Conflicting TeX root directives.' | endif
    if !empty(roots) && roots[0] !=# file
      let file = roots[0]
      continue
    endif
    if empty(filter(copy(lines), {_, v -> v =~# '^\s*\\documentclass\>'}))
      throw 'No main document found; add % !TeX root = ../main.tex near the top.'
    endif
    return file
  endfor
  throw 'TeX root chain is too deep.'
endfunction

function! LatexBuildStart() abort
  try
    let main = s:Root()
    if !exists('b:vimtex') || resolve(b:vimtex.tex) !=# main
      throw 'VimTeX root differs; check % !TeX root and reopen the file.'
    endif
    if b:vimtex.compiler.is_running() | throw 'Build already running; use :VimtexStop.' | endif
    for b in getbufinfo({'bufmodified': 1})
      if b.bufnr != bufnr('%') && (b.name =~? '\.\(tex\|bib\|sty\|cls\)$' || fnamemodify(b.name, ':t') =~# '^\.\?latexmkrc$')
        throw 'Save other modified TeX/Bib/config buffers first: ' . b.name
      endif
    endfor
    update
    VimtexCompile
    return 1
  catch
    echohl WarningMsg | echom v:exception | echohl None
    return 0
  endtry
endfunction
command! LatexBuild call LatexBuildStart()
command! LatexBuildLog VimtexCompileOutput
nnoremap <silent> <leader>lb :<C-u>LatexBuild<CR>
nnoremap <silent> <leader>lv :<C-u>VimtexView<CR>
nnoremap <silent> <leader>ls :<C-u>VimtexStop<CR>
nnoremap <silent> <leader>lo :<C-u>VimtexCompileOutput<CR>
