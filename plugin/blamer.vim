if has('win32') || exists('g:loaded_blamer_lua') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi! link NvimBlamerInfo Comment

command! -nargs=0 NvimBlamerAuto call nvimblamer#auto()
command! -nargs=0 NvimBlamerToggle call nvimblamer#toggle()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_blamer_lua = 1
