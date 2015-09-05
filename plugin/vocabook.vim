if exists("g:vocabook_initloaded") || &cp
  finish
endif

let g:vocabook_initloaded = 1


if !has('python')
    echo "vocabook.vim Error: Requires Vim compiled with +python or +python3"
    finish
endif

nnoremap <buffer> <leader>v :call vocabook#init()<CR>

if !exists("g:word_is_in_db")
  let g:word_is_in_db = 0
  "0 stands for not in database, 1 for in database
endif

if !exists("g:win_level")
  let g:win_level = 0
  "0 stands for having not been shown, 1 for entry list, 2 for entry detail
endif

if !exists("g:db_loaded")
  let g:de_loaded = 0
  "0 stands for having not been shown, 1 for entry list, 2 for entry detail
endif
