" ============================================================================
" File:        LinkToCodeBrowser.vim
" Maintainer:  Derek Bolt <derebolt@amazon.com>
" ============================================================================

function! LinkToCodeBrowser() range
    let b:packageRoot = ChompedSystem('git rev-parse --show-toplevel')
    let b:packageName = substitute(b:packageRoot, '.*/', '', '')
    let b:filePathRelativeToPackageRoot = substitute(expand('%:p'), b:packageRoot, '', '')
    let b:startLine = getpos("'<")[1]
    let b:endLine = getpos("'>")[1]

    let b:url = "https://code.amazon.com/packages/".b:packageName."/blobs/mainline/--/".b:filePathRelativeToPackageRoot."?hl_lines=".b:startLine."-".b:endLine."#line-".b:startLine
    let @* = b:url
    echo b:url
endfunction

function! ChompedSystem( ... )
    return substitute(call('system', a:000), '\n\+$', '', '')
endfunction

command -range LinkToCodeBrowser :call LinkToCodeBrowser()
