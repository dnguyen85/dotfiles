" Enable Mouse
set mouse=a

let $NVIM_TUI_ENABLE_TRUE_COLOR=1
set background=dark
colorscheme solarized_nvimqt
GuiFont! DejaVu Sans Mono for PowerLine:h12

" Right Click Context Menu (Copy-Cut-Paste)
nnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>
inoremap <silent><RightMouse> <Esc>:call GuiShowContextMenu()<CR>
vnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>gv

let s:fontsize = 11
function! AdjustFontSize(amount)
    let s:fontsize = s:fontsize + a:amount
    :execute "GuiFont! DejaVu Sans Mono for Powerline:h" . s:fontsize
endfunction

noremap <C-ScrollWheelUp> :call AdjustFontSize(1)<CR>
noremap <C-ScrollWheelDown> :call AdjustFontSize(-1)<CR>
