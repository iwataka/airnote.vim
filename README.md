# Airnote

Fast and simple note-taking plugin for Vim.
This has the features like below:

+ Edit or delete notes with file-name completion

  You can edit a note by this command:
  ```vim
  :Note [file-name]
  ```
  or `:Note` with no arguments and then get a prompt.

  Use `:NoteDelete` command to delete a note.

+ Search a note by tags with tag-name completion

  You can search the specified note by tags
  ```vim
  :Note @[tag-name]
  ```
  If you use markdown as the note syntax, you don't have to do any settings for it!

## Related Projects

+ [memolist](https://github.com/glidenote/memolist.vim)
+ [vim-notes](https://github.com/xolox/vim-notes)
