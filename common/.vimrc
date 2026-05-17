set nocompatible
filetype plugin indent on
syntax enable

set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,euc-kr,cp949,latin1
set backspace=indent,eol,start
set visualbell
set noerrorbells
set autoread
set hidden
set swapfile
set undofile
silent! call mkdir(expand('~/.vim/undo'), 'p')
set undodir=~/.vim/undo//

set autoindent
set smartindent
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set shiftround

set hlsearch
set incsearch
set ignorecase
set smartcase
nnoremap <leader><space> :nohlsearch<CR>

set complete-=i
set lazyredraw
set display+=lastline

set laststatus=2
set ruler
set wildmenu
set number
set showcmd
set title
set mouse=a

if has('termguicolors')
  set termguicolors
endif

let s:plug_path = expand('~/.vim/autoload/plug.vim')
if empty(glob(s:plug_path)) && executable('curl') && empty($DOTFILES_SKIP_NETWORK)
  silent execute '!curl -fLo ' . shellescape(s:plug_path) . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

if !empty(glob(s:plug_path))
  call plug#begin('~/.vim/plugged')
  Plug 'tpope/vim-sensible'
  Plug 'editorconfig/editorconfig-vim'
  call plug#end()
endif

autocmd FileType html setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
autocmd FileType ruby setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd FileType javascript,typescript,json,yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
