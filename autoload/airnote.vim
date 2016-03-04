let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists('g:airnote_path')
  let g:airnote_path = expand('~/notes')
endif
if !exists('g:airnote_suffix')
  let g:airnote_suffix = 'md'
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
if !exists('g:airnote_default_open_cmd')
  let g:airnote_default_open_cmd = 'edit'
endif
if !exists('g:airnote_auto_mkdir')
  let g:airnote_auto_mkdir = 1
endif
if !exists('g:airnote_ctags_executable')
  let g:airnote_ctags_executable =
        \ executable('ctags-exuberant') ? 'ctags-exuberant' :
        \ executable('ctags') ? 'ctags' :
        \ ''
endif
if !exists('g:airnote_enable_cache')
  let g:airnote_enable_cache = 0
endif
if !exists('g:airnote_cache_path')
  let g:airnote_cache_path = expand('~/.cache/airnote.vim')
endif

let s:cmd_fname_separator = '://'
let s:dir2localtime = {}
let s:dir2tags = {}

if !isdirectory(g:airnote_path)
  call mkdir(g:airnote_path, 'p')
endif
if !isdirectory(g:airnote_cache_path)
  call mkdir(g:airnote_cache_path, 'p')
endif

fu! s:localtime_cache_file()
  return substitute(g:airnote_cache_path, '\v/*$', '', '').'/localtime.txt'
endfu

fu! s:tags_cache_file()
  return substitute(g:airnote_cache_path, '\v/*$', '', '').'/tags.txt'
endfu

fu! s:write_cache()
  call writefile(split(string(s:dir2localtime), '\n'), s:localtime_cache_file())
  call writefile(split(string(s:dir2tags), '\n'), s:tags_cache_file())
endfu

fu! s:read_cache()
  let localtime_cache = s:localtime_cache_file()
  let tags_cache = s:tags_cache_file()
  if filereadable(localtime_cache)
    exe 'let s:dir2localtime = '.join(readfile(localtime_cache), ' ')
  endif
  if filereadable(tags_cache)
    exe 'let s:dir2tags = '.join(readfile(tags_cache), ' ')
  endif
endfu

augroup airnote
  autocmd!
  autocmd VimLeave * if g:airnote_enable_cache | call s:write_cache() | endif
augroup END

if g:airnote_enable_cache
  call s:read_cache()
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

fu! s:ctags(dir)
  " Remove trailing slashes
  let dir = substitute(a:dir, '\v/*$', '', '')
  " Set 0 if no ctags search has occurred so far
  let last_update = get(s:dir2localtime, dir, 0)
  let cmd = g:airnote_ctags_executable
  if empty(cmd)
    return {}
  endif
  let files = split(globpath(dir, '**/*'), '\n')
  let tags = get(s:dir2tags, dir, {})

  " Filter notes by their last modification time
  let files = filter(files, 'getftime(v:val) > last_update')
  " Update if there are files modified from the last ctags search
  if !empty(files)
    let tags = filter(tags, 'index(files, v:val.fname) == -1')
    let output = system(cmd.' --recurse=yes --append=no -f - '.join(files, ' '))
    for line in split(output, '\v\n+')
      let sep = split(split(line, '\V;"')[0], '\t')
      " Cygwin Warning might be included
      if len(sep) == 3
        let item = { 'fname': sep[1], 'cmd': escape(sep[2], '[]') }
        let tags[sep[0]] = item
      endif
    endfor
  endif

  let s:dir2tags[dir] = tags
  let s:dir2localtime[dir] = localtime()
  return tags
endfu

" Open the specified file by the specified command if it's not active.
fu! s:open(cmd, fname)
  let fname = fnamemodify(a:fname, ':p')
  if fnamemodify(bufname('%'), ':p') != fname
    let dir = fnamemodify(fname, ':h')
    if g:airnote_auto_mkdir && !isdirectory(dir)
      call mkdir(dir, 'p')
    endif
    silent exe a:cmd.' '.fname
  endif
endfu

fu! airnote#open(...)
  unlet! s:tags
  if a:0
    let input = a:1
  else
    call inputsave()
    let input = input(g:airnote_open_prompt, '', 'customlist,airnote#open_complete')
    call inputrestore()
  endif
  if !empty(input)
    " tag jump
    if input =~ "^@"
      if !exists('s:tags')
        let s:tags = s:ctags(g:airnote_path)
      endif
      let key = input[1:-1]
      if has_key(s:tags, key)
        let item = s:tags[input[1:-1]]
        call s:open(g:airnote_default_open_cmd, item.fname)
        silent exe item.cmd
      else
        echo "\rInvalid tag: ".key
      endif
    " just open the specified file
    else
      if empty(fnamemodify(input, ':e'))
        " Input string may be followed by dot, such as 'foo.'
        let input = substitute(input, '\v\.?$', '', '')
        let input .= substitute(g:airnote_suffix, '\v^\.?', '.', '')
      endif
      let sep = s:separate(input, s:cmd_fname_separator)
      if type(sep) == type('')
        let path = substitute(g:airnote_path, '\v/?$', '/', '').sep
        call s:open(g:airnote_default_open_cmd, path)
      else
        let [cmd, fname] = sep
        let path = substitute(g:airnote_path, '\v/?$', '/', '').fname
        call s:open(cmd, path)
      endif
      if !filereadable(path)
        let time = strftime(g:airnote_date_format)
        if !empty(time)
          let line = printf(&commentstring, time)
          call setline(1, line)
        endif
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
      let fname .= substitute(g:airnote_suffix, '\v^\.?', '.', '')
    endif
    let path = substitute(g:airnote_path, '\v/?$', '/', '').fname
    if !filereadable(path)
      echo "\r".fname.' is not a existing file.'
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

fu! airnote#open_complete(A, L, P)
  if a:A =~ "^@"
    if !exists('s:tags')
      let s:tags = s:ctags(g:airnote_path)
    endif
    return map(filter(keys(s:tags), 'v:val =~ a:A[1:-1]'), '"@".v:val')
  else
    let sep = s:separate(a:A, s:cmd_fname_separator)
    if type(sep) == type('')
      return airnote#delete_complete(a:A, a:L, a:P)
    elseif type(sep) == type([])
      let [cmd, fname] = sep
      let cands = airnote#delete_complete(fname, a:L, a:P)
      return map(cands, 'cmd.s:cmd_fname_separator.v:val')
    endif
  endif
endfu

fu! airnote#delete_complete(A, L, P)
  let path = fnamemodify(g:airnote_path, ':p')
  let len = len(path)
  let cands = split(globpath(g:airnote_path, a:A.'*'))
  return map(map(cands, 'isdirectory(v:val) ? v:val.expand("/") : v:val'),
        \ 'strpart(v:val, len)')
endfu

let &cpo = s:save_cpo
unlet s:save_cpo
