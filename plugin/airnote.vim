com! -nargs=? -complete=customlist,NoteComplete Note call airnote#edit(<f-args>)
com! -nargs=? -complete=customlist,NoteComplete NoteDelete call airnote#delete(<f-args>)
com! -nargs=? NoteGrep call airnote#grep(<f-args>)
