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
nnoremap <leader>v :call <SID>VocabNoteBook()<cr>
autocmd VimLeave * call <SID>CloseDB()
endfunction

function! s:VocabNoteBook()
    Python vocabnotebook.main()
endfunction

function! s:CloseDB()
    Python vocabnotebook.closedb()
endfunction

function! s:Sdcv()
    let exp1=system('sdcv -n ' . shellescape(expand("<cword>")))
    windo if expand("%")=="d-tmp" |q!|endif
    9sp d-tmp
    setlocal buftype=nofile bufhidden=delete noswapfile
    1s/^/\=exp1/
    normal gg
    "wincmd p
endfunction

nnoremap <leader>d :call <SID>Sdcv()<cr>
autocmd VimEnter *.mkd call <SID>LoadVNB()
autocmd VimEnter *.markdown call <SID>LoadVNB()
autocmd VimEnter *.md call <SID>LoadVNB()
autocmd VimEnter *.hackernews call <SID>LoadVNB()
autocmd VimEnter *.qr call <SID>LoadVNB()
autocmd VimEnter *.txt call <SID>LoadVNB()
