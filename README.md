# airnote.vim

## Introduction

Note-taking is a huge part of your life and a source of your thoughts, so it should be as speedy and intuitive as possible.
This plug-in allows you to open and delete notes blazing fast and, in addition, search one of them by tags and jump to there.
You can do these things with appropriate completion and command design.

## Philosophy

Any idea coming into your head goes away if you don't give a shape to it and you should write it down or do something like that to prevent it.
At this point, the note you wrote is a little messy and needs to be more sophisticated.
Rewriting it to new one and dividing it into multiple sub-categories, you'll get really important things.
Thus, airnote.vim has these philosophies:

+ Fast access
+ Less commands and more functionalities
+ Category-based
+ Syntax-agnostic
+ Friendly with other distraction-free plug-in (like [goyo.vim](https://github.com/junegunn/goyo.vim/))

## Usage

+ Edit or delete notes with file-name completion

  You can edit a note by this command:
  ```vim
  :Note [file-name]
  ```
  or `:Note` with no arguments and then get a prompt.

  Use `:NoteDelete` command to delete a note.

+ Search one of your notes by tags with tag-name completion

  You can search the specified note by tags
  ```vim
  :Note @[tag-name]
  ```

  This utilizes `ctags`, so you may have to add some settings to your `.ctags` file.
  In case that you use markdown as a note syntax, add below sentence to `.ctags`.
  ```
  --langdef=markdown
  --langmap=markdown:.md
  --regex-markdown=/^#+\s*(.+)/\1/
  ```

## Installation

I recommend to use [vim-plug](https://github.com/junegunn/vim-plug/) if you don't have your favorite plug-in manager.
```vim
Plug 'iwataka/airnote.vim', { 'on': ['Note', 'NoteDelete'] }
```

## Related Projects

+ [memolist](https://github.com/glidenote/memolist.vim)
+ [vim-notes](https://github.com/xolox/vim-notes)
