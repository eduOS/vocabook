if !exists("g:word_is_in_db")
  let g:word_is_in_db = 0
  "0 stands for not in database, 1 for in database
endif

if !exists("g:win_level")
  let g:win_level = 0
  "0 stands for having not been shown, 1 for entry list, 2 for entry detail
endif

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
autocmd VimLeave * call <SID>CloseDB()
endfunction

function! s:CloseDB()
    Python vocabnotebook.closedb()
endfunction

autocmd VimEnter *.mkd call <SID>LoadVNB()
autocmd VimEnter *.markdown call <SID>LoadVNB()
autocmd VimEnter *.md call <SID>LoadVNB()
autocmd VimEnter *.hackernews call <SID>LoadVNB()
autocmd VimEnter *.qr call <SID>LoadVNB()
autocmd VimEnter *.txt call <SID>LoadVNB()
