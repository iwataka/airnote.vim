if &compatible || (exists('g:loaded_airnote') && g:loaded_airnote)
  finish
endif
let g:loaded_airnote = 1

fu! airnote#edit(cmd, ...)
  let fname = a:0 ? a:1 : input(g:airnote_edit_prompt, '', 'customlist,airnote#complete')
  if !empty(fname)
    if empty(fnamemodify(fname, ':e'))
      let fname .= airnote#extension()
    endif
    let path = airnote#directory().fname
    silent exe a:cmd.' '.path
    if !filereadable(path)
      let time = strftime(g:airnote_date_format)
      if !empty(time)
        let line = printf(&commentstring, time)
        call setline(1, line)
      endif
    endif
  endif
endfu

com! -nargs=? -complete=customlist,airnote#complete Note
      \ call airnote#edit('edit', <f-args>)
com! -nargs=? -complete=customlist,airnote#complete NoteDelete
      \ call airnote#delete(<f-args>)
com! -nargs=? NoteGrep call airnote#grep(<f-args>)
