" Debug helpers
" set breakpoint at the current line
nnoremap <buffer> <leader>bs :call SetBreakpoint()<CR>:let @m = "dbstop at " . line('.') . " in " . expand('%')<CR>:SlimeSend1 <C-r>m<CR>
" step next
nnoremap <buffer> <Space> :let @m = "dbstep"<CR>:SlimeSend1 <C-r>m<CR>
" Print stack
nnoremap <buffer> <leader>ss :let @m = "dbstack"<CR>:SlimeSend1 <C-r>m<CR>
" Go down
nnoremap <buffer> <leader>sd :let @m = "dbdown"<CR>:SlimeSend1 <C-r>m<CR>
" Go up
nnoremap <buffer> <leader>su :let @m = "dbup"<CR>:SlimeSend1 <C-r>m<CR>
" step in
nnoremap <buffer> <C-Space> :let @m = "dbstep in"<CR>:SlimeSend1 <C-r>m<CR>
" step out
nnoremap <buffer> <leader>f :let @m = "dbstep out"<CR>:SlimeSend1 <C-r>m<CR>
" unset breakpoint at the current line
nnoremap <buffer> <leader>bd :call UnsetBreakpoint()<CR>:let @m = "dbclear at " . line('.') . " in " . expand('%')<CR>:SlimeSend1 <C-r>m<CR>
" delete all breakpoints
nnoremap <buffer> <leader>bc :call RemoveAllBreakpoints()<CR>:let @m = "dbclear all"<CR>:SlimeSend1 <C-r>m<CR>
" continue until next breakpoint or end of program
nnoremap <buffer> <leader>r :let @m = "dbcont"<CR>:SlimeSend1 <C-r>m<CR>
" put me in debug mode if there is an error or warning
nnoremap <buffer> <leader>e :let @m = "dbstop if error"<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>w :let @m = "dbstop if warning"<CR>:SlimeSend1 <C-r>m<CR>
" exit debug mode without removing breakpoints
nnoremap <buffer> <leader>k :let @m = "dbquit"<CR>:SlimeSend1 <C-r>m<CR>
" quit debugging mode and remove all breakpoints
nnoremap <buffer> <leader>q :call RemoveAllBreakpoints()<CR>:let @m = "dbclear all; dbquit"<CR>:SlimeSend1 <C-r>m<CR>

" Variable viewing
" Open file under cursor in GUI
nnoremap <buffer> <leader>mk :let @m = "edit " . expand('<cword>')<CR>:SlimeSend1 <C-r>m<CR>
" Open current file in GUI
nnoremap <buffer> <leader>mK :let @m = "edit " . expand('%:r')<CR>:SlimeSend1 <C-r>m<CR>
" Show workspace
nnoremap <buffer> <leader>mb :let @m = "workspace"<CR>:SlimeSend1 <C-r>m<CR>
" Open current variable under cursor in GUI variable viewer
nnoremap <buffer> K :let @m = "openvar('" . expand('<cword>') . "')"<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mO :let @m = "openvar('" . expand('<cWORD>') . "')"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>mo "my:let @m = "openvar('<C-R>m')"<CR>:SlimeSend1 <C-r>m<CR>
" See types of variable
nnoremap <buffer> <leader>mw :let @m = "whos " . expand('<cword>')<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mW :let @m = "whos " . expand('<cWORD>')<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>mw "my:let @m = "whos <C-R>m"<CR>:SlimeSend1 <C-r>m<CR>

" Metadata on variables
" Size of the variable under cursor
nnoremap <buffer> <leader>mz :let @m = "size(" . expand('<cword>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mZ :let @m = "size(" . expand('<cWORD>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>mz "my:let @m = "size(<C-R>m)"<CR>:SlimeSend1 <C-r>m<CR>
" Length of the variable under cursor 
nnoremap <buffer> <leader>ml :let @m = "length(" . expand('<cword>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mL :let @m = "length(" . expand('<cWORD>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>ml "my:let @m = "length(<C-R>m)"<CR>:SlimeSend1 <C-r>m<CR>
" Number of elements in the variable under cursor
nnoremap <buffer> <leader>mv :let @m = "numel(" . expand('<cword>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mV :let @m = "numel(" . expand('<cWORD>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>mv "my:let @m = "numel(<C-R>m)"<CR>:SlimeSend1 <C-r>m<CR>
" mean of the variable at point
nnoremap <buffer> <leader>me :let @m = "mean(" . expand('<cword>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mE :let @m = "mean(" . expand('<cWORD>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>me "my:let @m = "mean(<C-R>m)"<CR>:SlimeSend1 <C-r>m<CR>
" sum of the variable at point
nnoremap <buffer> <leader>m= :let @m = "sum(" . expand('<cword>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>m= "my:let @m = "sum(<C-R>m)"<CR>:SlimeSend1 <C-r>m<CR>
" cumulative sum of the variable at point
nnoremap <buffer> <leader>m+ :let @m = "cumsum(" . expand('<cword>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>m+ "my:let @m = "cumsum(<C-R>m)"<CR>:SlimeSend1 <C-r>m<CR>

" Simple plotting
" plot the vector
nnoremap <buffer> <leader>mpv :let @m = "plot(" . expand('<cword>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mpV :let @m = "plot(" . expand('<cWORD>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>mpv "my:let @m = "plot(<C-R>m)"<CR>:SlimeSend1 <C-r>m<CR>
" plot the matrix as a mesh plot
nnoremap <buffer> <leader>mpm :let @m = "mesh(" . expand('<cword>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mpM :let @m = "mesh(" . expand('<cWORD>') . ")"<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>mpm "my:let @m = "mesh(<C-R>m)"<CR>:SlimeSend1 <C-r>m<CR>

" Help
" show brief help on the function at point
nnoremap <buffer> <leader>mh :let @m = "help " . expand('<cword>')<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mH :let @m = "help " . expand('<cWORD>')<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>mh "my:let @m = "help <C-R>m"<CR>:SlimeSend1 <C-r>m<CR>
" open the complete GUI documentation of the function at point
nnoremap <buffer> <leader>md :let @m = "doc " . expand('<cword>')<CR>:SlimeSend1 <C-r>m<CR>
nnoremap <buffer> <leader>mD :let @m = "doc " . expand('<cWORD>')<CR>:SlimeSend1 <C-r>m<CR>
vnoremap <buffer> <leader>md "my:let @m = "doc <C-R>m"<CR>:SlimeSend1 <C-r>m<CR>

" Other commands
" clear screen
nnoremap <buffer> <leader>mc :let @m = "clc"<CR>:SlimeSend1 <C-r>m<CR>
" clear variable list
nnoremap <buffer> <leader>mu :let @m = "clear all"<CR>:SlimeSend1 <C-r>m<CR>
" run the current file
nnoremap <buffer> <leader>mm :let @m = expand('%:r')<CR>:SlimeSend1 <C-r>m<CR>
