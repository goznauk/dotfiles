set nocompatible
filetype plugin indent on
syntax enable
let mapleader = " "

set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,euc-kr,cp949,latin1
set backspace=indent,eol,start
set visualbell
set noerrorbells
set autoread
set hidden
set swapfile
set directory=~/.vim/swap//
set undofile
set undodir=~/.vim/undo//
set backupdir=~/.vim/backup//
silent! call mkdir(expand('~/.vim/swap'), 'p')
silent! call mkdir(expand('~/.vim/undo'), 'p')
silent! call mkdir(expand('~/.vim/backup'), 'p')

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
set splitright
set splitbelow

if has('termguicolors')
  set termguicolors
endif

let s:plug_path = expand('~/.vim/autoload/plug.vim')
if !empty(glob(s:plug_path))
  call plug#begin('~/.vim/plugged')
  Plug 'tpope/vim-sensible'
  Plug 'editorconfig/editorconfig-vim'
  call plug#end()
endif

augroup dotfiles_filetypes
  autocmd!
  autocmd FileType html setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType ruby setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
  autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
  autocmd FileType javascript,typescript,json,yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
augroup END
