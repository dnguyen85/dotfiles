" Eclim Java settings {{{
" Import class under cursor
nnoremap <silent> <buffer> <leader>i :JavaImport<cr>
" Search for javadocs of element under cursor
nnoremap <silent> <buffer> <leader>d :JavaDocSearch -x declarations<cr>
" Context sensitive search of element under cursor
nnoremap <silent> <buffer> <cr> :JavaSearchContext<cr>
" }}}

" debugger mappings {{{
nnoremap <silent> <localleader>q :JavaDebugStop<CR>
nnoremap <silent> <localleader>s :JavaDebugThreadSuspend<CR>
nnoremap <silent> <localleader>r :JavaDebugThreadResume<CR>
nnoremap <silent> <localleader>t :JavaDebugBreakpointToggle<CR>
nnoremap <silent> <localleader>b :JavaDebugBreakpointsList!<CR>
nnoremap <silent> <localleader>f :JavaDebugStep over<CR>
nnoremap <silent> <localleader>e :JavaDebugStep into<CR>
nnoremap <silent> <localleader>x :JavaDebugStep return<CR>
" }}}

