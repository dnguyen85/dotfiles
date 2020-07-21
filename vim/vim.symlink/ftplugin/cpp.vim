" Debugging
nnoremap <leader>bs :Break<CR> 
nnoremap <leader>bd :Clear<CR>
nnoremap <leader>bc :call TermDebugSendCommand('delete')<CR>
nnoremap <C-Space> :Step<CR>
nnoremap <Space> :Over<CR>
nnoremap <leader>f :Finish<CR>
nnoremap <leader>r :Continue<CR>
nnoremap <leader>e :call TermDebugSendCommand('p '.expand("<cword>"))<CR>
nnoremap <leader>E :call TermDebugSendCommand('p '.expand("<cWORD>"))<CR>
nnoremap <leader>u :Until<CR>
nnoremap <leader>a :Advance<CR>
nnoremap <leader>w :call TermDebugSendCommand('where')<CR>
nnoremap <leader>sd :call TermDebugSendCommand('down')<CR>
nnoremap <leader>su :call TermDebugSendCommand('up')<CR>
vnoremap <leader>e :EvalVisual<CR>
