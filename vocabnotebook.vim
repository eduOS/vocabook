if has('python')
    command! -nargs=1 Python python <args>
elseif has('python3')
    command! -nargs=1 Python python3 <args>
else
    echo "vocabnotebook.vim Error: Requires Vim compiled with +python or +python3"
    finish
endif

" Import Python code
execute "Python import sys"
execute "Python sys.path.append(r'" . expand("<sfile>:p:h") . "')"

function s:LoadVNB()
Python << EOF
if 'vocabnotebook' not in sys.modules:
    import vocabnotebook
else:
    import imp
    # Reload python module to avoid errors when updating plugin
    vocabnotebook = imp.reload(vocabnotebook)
EOF

"nnoremap <leader>v :set operatorfunc=<SID>VocabNoteBook<cr>g@
"vnoremap <leader>v :<c-u>call <SID>VocabNoteBook(visualmode())<cr>
nnoremap <leader>v :Python vocabnotebook.main()<cr>
nnoremap <leader>d :Python vocabnotebook.dict()<cr>

"noremap <buffer> u :Python vocabnotebook.save_pos()<cr>
"                   \u
"                   \:Python vocabnotebook.recall_pos()<cr>
"noremap <buffer> <C-R> :Python vocabnotebook.save_pos()<cr>
"                       \<C-R>
"                       \:Python vocabnotebook.recall_pos()<cr>

autocmd VimLeave * call <SID>CloseDB()
endfunction

if !exists("g:vo_marks")
    let g:vo_marks = {}
endif

function! s:CloseDB()
    Python vocabnotebook.closedb()
endfunction

autocmd VimEnter *.mkd call <SID>LoadVNB()
autocmd VimEnter *.markdown call <SID>LoadVNB()
autocmd VimEnter *.md call <SID>LoadVNB()
autocmd VimEnter *.hackernews call <SID>LoadVNB()
autocmd VimEnter *.qr call <SID>LoadVNB()
autocmd VimEnter *.txt call <SID>LoadVNB()
