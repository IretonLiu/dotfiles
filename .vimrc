" Templates
:autocmd BufNewFile *.cpp 0r ~/.vim/templates/skeleton.cpp

" Disable compatibility with vi which can cause unexpected issues.
set nocompatible

" Do not save backup files.
set nobackup

" ===================================================================

" github dark colour scheme
call plug#begin()
Plug 'wojciechkepka/vim-github-dark'
call plug#end()

" ===================================================================

" Enable type file detection. Vim will be able to try to detect the type of file in use.
filetype on

" Enable plugins and load plugin for the detected file type.
filetype plugin on

" Load an indent file for the detected file type.
filetype indent on

" ===================================================================

" auto indentation in vim
set autoindent
set smartindent

" Set shift width to 4 spaces.
set shiftwidth=4

" Set tab width to 4 columns.
set tabstop=4

" Use space characters instead of tabs.
set expandtab

" ===================================================================
" Visual Settings

" Set colorscheme
colorscheme ghdark

" Relative line numbers
set number relativenumber

" Highlight cursor line underneath the cursor horizontally.
hi CursorLine cterm=NONE ctermbg=5
set cursorline

" Highlight cursor line underneath the cursor vertically.
" set cursorcolumn

" Enable syntax highlighting
if has('syntax')
  syntax on
endif

" ===================================================================

" Enable auto completion menu after pressing TAB.
set wildmenu

" Make wildmenu behave like similar to Bash completion.
set wildmode=list:longest

" There are certain files that we would never want to edit with Vim.
" Wildmenu will ignore files with these extensions.
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" ===================================================================

" Show command
set showcmd

" Show the mode you are on the last line.
set showmode

" Show matching words during a search.
set showmatch

" Use highlighting when doing a search.
set hlsearch

" Set the commands to save in history default number is 20.
set history=1000

" Enable use of the mouse for all modes
if has('mouse')
  set mouse=a
endif

" Status bar
set laststatus=2


