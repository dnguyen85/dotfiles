if exists('g:loaded_vim_code_browse')
    finish
endif
let g:loaded_vim_code_browse = 1

function! s:code_amazon_com(opts, ...) abort
	let remote = a:opts.remote

	" This plugin should work only for amazon git packages. Thus the
	" remote address should include git.amazon.com.
	let is_amazon_code = matchstr(remote, 'git.amazon.com')
	if is_amazon_code ==# ''
		return ''
	endif

	" building a URL on the form:
	" https://code.amazon.com/packages/{pkg_name}/blobs/{commit_id}/--/{path_to_file}{line_path}
	" e.g.: https://code.amazon.com/packages/RAFulfillmentStackService/blobs/664e6b2eb45ec09478a314ff1bb5742f6a04506d/--/Config#L14-L15

	if a:opts.commit =~# '^\d\=$'
		let commit_id = a:opts.repo.rev_parse('HEAD')
	else
		let commit_id = a:opts.commit
	endif

	" The git remote URL is on the form:
	" ssh://git.amazon.com:2222/pkg/{pkg_name}
	" e.g.: ssh://git.amazon.com:2222/pkg/RAFulfillmentStackService
	" Thus the last part of the remote URL should be the name of the
	" package.
	let pkg_name = split(remote, '/')[-1]

	" Fugitive sends line1=0 if no line is selected
	if a:opts.line1 ==# 0
		let line_path = ''
	else
		let line_path = '#L' . a:opts.line1 . '-L' . a:opts.line2
	endif

 	let url = 'https://code.amazon.com/packages/' . pkg_name . '/blobs/' . commit_id . '/--/' . a:opts.path . line_path
	return url
endfunction

if !exists('g:fugitive_browse_handlers')
  let g:fugitive_browse_handlers = []
endif

call insert(g:fugitive_browse_handlers, function('s:code_amazon_com'))
