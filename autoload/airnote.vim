let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists('g:airnote_path')
  let g:airnote_path = expand('~/notes')
endif
if !exists('g:airnote_grep_format')
  let g:airnote_grep_format = 'grep %s %s'
endif
if !exists('g:airnote_suffix')
  let g:airnote_suffix = ''
endif
if !exists('g:airnote_date_format')
  let g:airnote_date_format = '%c'
endif
if !exists('g:airnote_open_prompt')
  let g:airnote_open_prompt = 'Open> '
endif
if !exists('g:airnote_delete_prompt')
  let g:airnote_delete_prompt = 'Delete> '
endif
if !exists('g:airnote_grep_prompt')
  let g:airnote_grep_prompt = 'Grep> '
endif
if !exists('g:airnote_default_open_cmd')
  let g:airnote_default_open_cmd = 'edit'
endif

let s:cmd_fname_separator = '://'

if !isdirectory(g:airnote_path)
  call mkdir(g:airnote_path, 'p')
endif

" s:separate('note.md', '://') == 'note.md'
" s:separate('edit://note.md', '://') == ['edit', 'note.md']
fu! s:separate(str, sep)
  let i = stridx(a:str, a:sep)
  if i == -1
    return a:str
  else
    return [a:str[0:(i - 1)], a:str[(i + len(a:sep)):-1]]
  endif
endfu

" s:assure_prefix('md', '.') == '.md'
" s:assure_prefix('.md', '.') == '.md'
fu! s:assure_prefix(str, s)
  if str !~ '\V\^'.s
    return s.str
  endif
  return str
endfu

" s:assure_suffix('foo/bar', '/') == 'foo/bar/'
" s:assure_suffix('foo/bar/', '/') == 'foo/bar/'
fu! s:assure_suffix(str, s)
  if str !~ '\V'.s.'\$'
    return str.s
  endif
  return str
endfu

fu! airnote#open(...)
  if a:0
    let input = a:1
  else
    call inputsave()
    let input = input(g:airnote_open_prompt, '', 'customlist,airnote#open_complete')
    call inputrestore()
  endif
  if !empty(input)
    if empty(fnamemodify(input, ':e'))
      let input .= s:assure_prefix(g:airnote_suffix, '.')
    endif
    let sep = s:separate(input, s:cmd_fname_separator)
    if type(sep) == type('')
      let path = s:assure_suffix(g:airnote_path, '/').sep
      silent exe g:airnote_default_open_cmd.' '.path
    else
      let [cmd, fname] = sep
      let path = s:assure_suffix(g:airnote_path, '/').fname
      silent exe cmd.' '.path
    endif
    if !filereadable(path)
      let time = strftime(g:airnote_date_format)
      if !empty(time)
        let line = printf(&commentstring, time)
        call setline(1, line)
      endif
    endif
  endif
endfu

fu! airnote#delete(...)
  if a:0
    let fname = a:1
  else
    call inputsave()
    let fname = input(g:airnote_delete_prompt, '', 'customlist,airnote#delete_complete')
    call inputrestore()
  endif
  if !empty(fname)
    if empty(fnamemodify(fname, ':e'))
      let fname .= s:assure_prefix(g:airnote_suffix, '.')
    endif
    let path = s:assure_suffix(g:airnote_path, '/').fname
    if !filereadable(path)
      echo "\n".fname.' is not a existing file.'
    else
      echo "\rReally want to delete ".fname.'? (y/n)'
      let reply = nr2char(getchar())
      if reply =~ '[yY]'
        if delete(path)
          echoe "\rFailed to delete ".fname
        else
          if bufexists(bufnr(path))
            silent exe 'bwipeout '.bufnr(path)
          endif
          echo "\rSucceeded to delete ".fname
        endif
      endif
    endif
  endif
endfu

fu! airnote#grep(...)
  if a:0
    let keyword = a:1
  else
    call inputsave()
    let keyword = input(g:airnote_grep_prompt)
    call inputrestore()
  endif
  if !empty(keyword)
    silent exe printf(g:airnote_grep_format, keyword, g:airnote_path)
  endif
endfu

fu! airnote#open_complete(A, L, P)
  let sep = s:separate(a:A, s:cmd_fname_separator)
  if type(sep) == type('')
    return airnote#delete_complete(a:A, a:L, a:P)
  elseif type(sep) == type([])
    let [cmd, fname] = sep
    let cands = airnote#delete_complete(fname, a:L, a:P)
    return map(cands, 'cmd.s:cmd_fname_separator.v:val')
  endif
endfu

fu! airnote#delete_complete(A, L, P)
  let path = fnamemodify(g:airnote_path, ':p')
  let len = len(path)
  let cands = split(globpath(g:airnote_path, a:A.'*'))
  return map(map(cands, 'isdirectory(v:val) ? v:val."/" : v:val'),
        \ 'strpart(v:val, len)')
endfu

let &cpo = s:save_cpo
unlet s:save_cpo
