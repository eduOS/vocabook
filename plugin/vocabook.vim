if exists("g:vocabook_initloaded") || &cp
  finish
endif

let g:vocabook_initloaded = 1


if !has('python')
    echo "vocabook.vim Error: Requires Vim compiled with +python or +python3"
    finish
endif

if !exists("t:win_level")
  let t:win_level = 0
  "0 stands for having not been shown, 1 for entry list, 2 for entry detail
endif

if !exists("g:db_loaded")
  let g:db_loaded = 0
  "0 stands for having not been shown, 1 for entry list, 2 for entry detail
endif

function! s:showInit()
    if t:win_level == 0
        call pyvocabook#init()
    endif
endfunction

nnoremap <buffer> <leader>v :call <SID>showInit()<CR>
