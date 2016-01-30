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
if !exists('g:airnote_edit_prompt')
  let g:airnote_edit_prompt = 'Edit> '
endif
if !exists('g:airnote_delete_prompt')
  let g:airnote_delete_prompt = 'Delete> '
endif
if !exists('g:airnote_grep_prompt')
  let g:airnote_grep_prompt = 'Grep> '
endif

if !isdirectory(g:airnote_path)
  call mkdir(g:airnote_path, 'p')
endif

fu! airnote#delete(...)
  let fname = a:0 ? a:1 : input(g:airnote_delete_prompt, '', 'customlist,airnote#complete')
  if !empty(fname)
    if empty(fnamemodify(fname, ':e'))
      let fname .= airnote#extension()
    endif
    let path = airnote#directory().fname
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
  let keyword = a:0 ? a:1 : input(g:airnote_grep_prompt)
  if !empty(keyword)
    silent exe printf(g:airnote_grep_format, keyword, g:airnote_path)
  endif
endfu

fu! airnote#directory()
  if g:airnote_path =~ '.*/$'
    return g:airnote_path
  else
    return g:airnote_path.'/'
  endif
endfu

fu! airnote#extension()
  if empty(g:airnote_suffix) || g:airnote_suffix =~ '^\..*'
    return g:airnote_suffix
  else
    return '.'.g:airnote_suffix
  endif
endfu

fu! airnote#complete(A, L, P)
  let path = fnamemodify(g:airnote_path, ':p')
  let len = len(path)
  let cands = split(globpath(g:airnote_path, a:A.'*'))
  return map(map(cands, 'isdirectory(v:val) ? v:val."/" : v:val'),
        \ 'strpart(v:val, len)')
endfu

let &cpo = s:save_cpo
unlet s:save_cpo
