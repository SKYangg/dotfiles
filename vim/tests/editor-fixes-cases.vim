" Load with the real vimrc, -i NONE -n; no browsers or language servers.
call assert_equal(0, &autowrite)
call assert_equal('<Nop>', maparg('Q','n'))
call assert_equal(':<C-U>nohlsearch<CR>', maparg("\<Esc>\<Esc>",'n'))
let fixture=tempname().'.md'
call writefile(['# First', 'second', 'third'],fixture)
execute 'edit '.fnameescape(fixture)
call cursor(3,1)
write
bdelete
execute 'edit '.fnameescape(fixture)
call assert_equal(3,line('.'),'last cursor position')
call assert_equal(0,&spell)
call feedkeys(' mw','xt')
call assert_equal(1,&spell)
call feedkeys(' mw','xt')
call assert_equal(0,&spell)
for [trigger, expected] in items({'mdmath':'$$','mdfig':'![','mdpaper':'# ','marpdoc':'marp: true','marpslide':'---','marpimage':'width:','marpmath':'$$','marpnote':'<!--'})
  enew!
  setfiletype markdown
  call setline(1,trigger)
  call cursor(1,strlen(trigger))
  call feedkeys("A\<C-R>=UltiSnips#ExpandSnippet()\<CR>\<Esc>",'xt')
  call assert_true(stridx(join(getline(1,'$'),"\n"),expected)>=0,'snippet '.trigger)
endfor
if !empty(v:errors)
 for error in v:errors | echomsg error | endfor
 cquit
endif
qa!
