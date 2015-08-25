if exists("b:current_syntax")
  finish
endif

syntax match VNBTag "\v^(Tags|Sentences):" nextgroup=VNBInput skipwhite
highlight VNBTag cterm=bold ctermfg=DarkRed
syntax match VNBInput "\v.*$" 
highlight link VNBInput SpecialComment
syntax match VNBTag1 "\v^(Word|Definition|Excerpts):" 
highlight VNBTag1 cterm=none ctermfg=LightRed
syntax match VNBComment "\v^# ?.*$" 
highlight link VNBComment Comment
syntax match VNBGuide "\v^Guide: .*$"
highlight link VNBGuide Identifier
syntax match VNBWord "\v[a-z]+\.\w{,3}\.\d{,3}"
highlight link VNBWord Underlined

let b:current_syntax = "vocabook"
