" --- Minimal Vim starter ---
let mapleader=" "            " Use Space as <leader>

set number                   " Line numbers
set ignorecase smartcase     " Smarter search
set incsearch                " Live search
set expandtab                " Tabs -> spaces
set shiftwidth=4             " Indent width
set tabstop=4                " Tab display width
set clipboard=unnamedplus    " System clipboard
syntax on
filetype plugin indent on

" --- Shortcuts ---
nnoremap <C-s> :w<CR>                    " Save
inoremap <C-s> <Esc>:w<CR>a              " Save (insert mode)
nnoremap <leader>/ :nohlsearch<CR>       " Clear search highlight
nnoremap <leader>dw :keeppatterns s/^\s\+//<CR>  " Strip leading spaces (current line)

