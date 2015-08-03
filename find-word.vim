nnoremap <localleader>f :set operatorfunc=<SID>Corpus<cr>g@
vnoremap <localleader>f :<c-u>call <SID>Corpus(visualmode())<cr>
command! -nargs=1 Findword :call <SID>Corpus(<f-args>)

function! s:Corpus(type_word)
    let saved_unnamed_register = @@

    if a:type_word ==# 'v'
        execute "normal! `<v`>y"
    elseif a:type_word ==# 'char'
        execute "normal! `[v`]y"
    else
        "let word = substitute(a:type, '"', '', 'g')
        let @@ = a:type_word 
    endif

    silent execute "grep! -R " . shellescape(@@) . " ~/Documents/corpora/"  . " . " 
    copen
    "exe normal! "/that"<cr>

    let @@ = saved_unnamed_register 
endfunction
