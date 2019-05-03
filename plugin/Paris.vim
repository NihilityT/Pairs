if !exists('g:PairsRule')
	let g:PairsRule = {
			\	'*': {
			\		'[':']',
			\		'{':'}',
			\		'(':')',
			\		"'":"'",
			\		'"':'"',
			\	},
			\	'html,xml': {
			\		'\v\<([^/>[:blank:]]+)@(\s+[^=/[:blank:]]+@(\=("@([^"]+|\")*"|''@([^'']+|\\'')*''))?)*\s*\>':'</\1>',
			\	},
			\}
endif

function! PairsInsert(key)
	execute 'normal! i'.a:key

	let linestr = getline('.')
	let curpos = getcurpos()
	let curpos[2] += 1
	call setpos('.', curpos)

	for [open, close] in items(PairsGetMapping()[a:key])
		let escaped_open = substitute(open, ';', '\;', 'g')
		let escaped_close = substitute(close, ';', '\;', 'g')
		execute 'keeppatterns substitute;\V'.escaped_open.'\v%#;\0'.escaped_close.';'
	endfor

	call setpos('.', curpos)

	return ''
endfunction


function! PairsGetMapping()
	if exists('s:PairsMapping')
		return s:PairsMapping
	endif

	let r = {}

	for filetypes in keys(g:PairsRule)
		let filetype_lst = split(filetypes, '\s*,\s*')

		if index(filetype_lst , &filetype) == -1 && index(filetype_lst, '*') == -1
			continue
		endif

		for [open, close] in items(g:PairsRule[filetypes])
			let lastchar = open[-1:]
			if exists('r[lastchar]')
				let r[lastchar][open] = close
			else
				let r[lastchar] = {open: close}
			endif
		endfor
	endfor

	let s:PairsMapping = r
	return r
endfunction

function! s:PairUnmap()
	for lastchar in keys(PairsGetMapping())
		execute 'silent! iunmap <buffer> '.lastchar
	endfor
	unlet s:PairsMapping
endfunction

function! PairsMap()
	call s:PairUnmap()

	for lastchar in keys(PairsGetMapping())
		let escaped_lastchar = lastchar ==# "'" ? "''" : lastchar
		execute 'inoremap <buffer> <silent> '.lastchar." <C-X><C-R>=PairsInsert('".escaped_lastchar."')<CR>"
	endfor
endfunction

autocmd BufNewFile,BufRead * call PairsMap()
