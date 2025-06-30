-- Basic syntax highlighting for Hyprland config files
vim.cmd([[
  syntax keyword hyprlangKeyword monitor exec bind workspace source
  syntax keyword hyprlangSection input general decoration animations gestures misc device
  syntax match hyprlangVariable "\$\w\+"
  syntax match hyprlangComment "#.*$"
  syntax match hyprlangNumber "\<\d\+\>"
  syntax region hyprlangString start=/"/ end=/"/ skip=/\\"/ 
  
  highlight link hyprlangKeyword Keyword
  highlight link hyprlangSection Type
  highlight link hyprlangVariable Identifier
  highlight link hyprlangComment Comment
  highlight link hyprlangNumber Number
  highlight link hyprlangString String
]]) 