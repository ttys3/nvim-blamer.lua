if has('win32') || exists('g:loaded_blamer_lua') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi! link GitLens Comment

" augroup BlamerLua
"   autocmd CursorHold   * lua require'blamer'.blameVirtText()
"   autocmd CursorMoved  * lua require'blamer'.clearBlameVirtText()
"   autocmd CursorMovedI * lua require'blamer'.clearBlameVirtText()
" augroup end

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_blamer_lua = 1
