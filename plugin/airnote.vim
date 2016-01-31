if &compatible || (exists('g:loaded_airnote') && g:loaded_airnote)
  finish
endif
let g:loaded_airnote = 1

com! -nargs=? -complete=customlist,airnote#open_complete Note
      \ call airnote#open(<f-args>)
com! -nargs=? -complete=customlist,airnote#delete_complete NoteDelete
      \ call airnote#delete(<f-args>)
