if exists("b:current_syntax")
  finish
endif

echom "syntax goes here"
syntax keyword TagHighlight Word: Definition: Tags: Sentences: 
syntax keyword TagHighlight Word Definition Tags Sentences 
highlight link TagHighlight Keyword

let b:current_syntax = "vocabook"

"hi GuideHighlight term=bold cterm=bold gui=bold ctermfg=green guifg=green
"syn match GuideHighlight "\v^Guide: .*$"
"hi WordHighlight term=bold cterm=bold gui=bold ctermfg=red guifg=red
"syn match WordHighlight "\v[a-z]+\.\w{,3}\.\d{,3}"
"hi TagHighlight term=bold cterm=bold gui=bold ctermfg=blue guifg=blue
"syn match TagHighlight "\v^(Word|Definition|Tags|Sentences):"

