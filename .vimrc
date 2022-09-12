" Templates
:autocmd BufNewFile *.cpp 0r ~/.vim/templates/skeleton.cpp

" Enable syntax highlighting
if has('syntax')
  syntax on
endif

" Enable use of the mouse for all modes
if has('mouse')
  set mouse=a
endif

" auto indentation in vim
set autoindent
set smartindent

" Relative line numbers
set number relativenumber

" Set the command window height to 2 lines, to avoid many cases of having to
" press <Enter> to continue
set cmdheight=2