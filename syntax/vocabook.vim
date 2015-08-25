if exists("b:current_syntax")
  finish
endif

syntax match VNBTag /\v^(Tags|Sentences):/ nextgroup=VNBInput skipwhite
syntax match VNBInput /\v.*$/ contained skipwhite
highlight link VNBTag Keyword
highlight link VNBInput SpecialComment
"hi def VNBTag guibg=Yellow guifg=Blue
"hi def VNBInput guibg=Green guifg=White

syntax match VNBTag1 "\v^(Word|Definition|Excerpts):" 
highlight link VNBTag1 Keyword

syntax match VNBComment "\v^# ?.*$" 
highlight link VNBComment Comment
syntax match VNBGuide "\v^Guide: .*$"
highlight link VNBGuide Identifier
syntax match VNBWord "\v[a-z]+\.\w{,3}\.\d{,3}"
highlight link VNBWord Underlined

let b:current_syntax = "vocabook"
