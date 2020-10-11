set nocompatible

set encoding=UTF-8
set fileencoding=UTF-8
set fileencodings=utf8,euc-kr,cp949,cp932,euc-jp,shift-jis,big5,latin1,ucs-2le
set visualbell
set backspace=indent,eol,start
set swapfile

" Indent options
set autoindent " New lines inherit the indentation of previous lines.
set tabstop=2 " Indent using two spaces.
set expandtab " Convert tabs to spaces.
set shiftwidth=2 " When shifting, indent using four spaces.
set shiftround " When shifting lines, round the indentation to the nearest multiple of “shiftwidth.”
set smarttab " Insert “tabstop” number of spaces when the “tab” key is pressed.
set cindent
set smartindent

" Search options
set hlsearch " Highlight searched keyword
nnoremap i :noh<cr>i
nnoremap o :noh<cr>o
nnoremap O :noh<cr>O
set incsearch " Incremental search that shows partial matches.
set ignorecase " Automatically switch search to case-sensitive when search query contains an uppercase letter.

" Performance options
set complete-=i " Limit the files searched for auto-completes.
set lazyredraw " Don’t update screen during macro and script execution.

" Text rendering options
set display+=lastline " Always try to show a paragraph’s last line.
set fileencodings=utf-8 " Set file encoding
syntax enable

" UI options
set laststatus=2 " Always display the status bar.
set ruler " Always show cursor position.
set wildmenu " Display command line’s tab complete options as a menu.
set tabpagemax=50 " Maximum number of tab pages that can be opened from the command line.
set number " Show line number
set noerrorbells " Disable beep on errors.은
set title " Set the window’s title, reflecting the file currently being edited.
" Only for unix users.
set mouse=a " Enable mouse for scrolling and resizing.
" vim-gtk is needed at this point
vmap <C-c> "+y
map <C-v> "+p
imap <C-v> <esc><C-v>
set showcmd

" Miscellaneous Options
set autoread " Automatically re-read files if unmodified inside Vim.

" crypto method
set cm=blowfish2


" Auto install plugins
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Specify a directory for plugins
call plug#begin('~/.vim/plugged')

" UI plugins
Plug 'preservim/nerdtree'

" Color themes
Plug 'doums/darcula'

" Lightline settings
Plug 'itchyny/lightline.vim'

" Language syntaxes
Plug 'leafgarland/typescript-vim'

" Initialize plugin system
call plug#end()

" Color scheme settings
colo darcula
set termguicolors
" TODO: Find a way to prevent syntax highlighting from being disabled over color-column.
highlight ColorColumn guibg=#2d2d2d 
let &colorcolumn="".join(range(100, 999),",")

" Nerdtree settings
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
map <C-n> :NERDTreeToggle<CR>
let g:NERDTreeDirArrowExpandable = ''
let g:NERDTreeDirArrowCollapsible = ''

" Lightline settings
set noshowmode
let g:lightline = { 'colorscheme': 'darculaOriginal' }


autocmd Filetype html setlocal ts=2 sw=2 expandtab
autocmd Filetype ruby setlocal ts=2 sw=2 expandtab
autocmd Filetype python setlocal ts=4 sw=4 expandtab
autocmd Filetype javascript setlocal ts=2 sw=2 sts=0 noexpandtab
