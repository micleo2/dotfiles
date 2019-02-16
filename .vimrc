"""""""""""""""""""""""""""""""""""""
" Allan MacGregor Vimrc configuration
"""""""""""""""""""""""""""""""""""""
set nocompatible
syntax on
set nowrap
set encoding=utf8

"""" START Vundle Configuration

" Disable file type for vundle
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" Utility
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'tpope/vim-surround'
Plugin 'morhetz/gruvbox'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'airblade/vim-gitgutter'
Plugin 'majutsushi/tagbar'
Plugin 'universal-ctags/ctags'
Plugin 'tomtom/tcomment_vim'
Plugin 'scrooloose/syntastic'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'

" for react
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'

" React code snippets
Plugin 'epilande/vim-react-snippets'

" textobjects
Plugin 'kana/vim-textobj-user'
Plugin 'kana/vim-textobj-line'
Plugin 'kana/vim-textobj-indent'
Plugin 'kana/vim-textobj-entire'
Plugin 'kana/vim-textobj-underscore'
Plugin 'sgur/vim-textobj-parameter'

" Themes
Plugin 'ryanoasis/vim-devicons'

call vundle#end()            " required
filetype plugin indent on    " required
"""" END Vundle Configuration

"""""""""""""""""""""""""""""""""""""
" Configuration Section
"""""""""""""""""""""""""""""""""""""

" Show linenumbers
set number
set relativenumber
set ruler

" highlight/searching
set incsearch
set hls

" Set Proper Tabs
set tabstop=2
set shiftwidth=2
set smarttab
set expandtab

" for easier :find completion
set path=$PWD/**

" to enable autocompletion from macros, keybindings etc.
set wildcharm=<C-z>

" change buffers without saving
set hidden

" Tagbar
let g:tabgar_autofocus=1
let g:tagbar_show_linenumbers = -1
"
" enable line numbers
let NERDTreeShowLineNumbers=1
" make sure relative line numbers are used
autocmd FileType nerdtree setlocal relativenumber

" Always display the status line
set laststatus=2
"
" No ARRRROWWS!!!!
nnoremap <Up>    :resize +2<CR>
nnoremap <Down>  :resize -2<CR>
nnoremap <Left>  :vertical resize +2<CR>
nnoremap <Right> :vertical resize -2<CR>

" Enable highlighting of the current line
set cursorline


"""""""""""""""""""""""""""""""""""""
" Mappings configurationn
"""""""""""""""""""""""""""""""""""""
map <C-f> :NERDTreeToggle<CR>
map <C-t> :TagbarToggle<CR>
map <C-g> :GitGutterAll<CR>
nnoremap <leader>c :!ctags -R<CR>
nnoremap <leader>j :tjump /
nnoremap <leader>m :CtrlPTag<CR>

" this is for easy buffer access
nnoremap gb :ls<CR>:b<Space>
nnoremap <Leader>b :buffer <C-z><S-Tab>

" for ease of buffer completion
set wildmenu
set wildmode=longest:full,full
set wildignore=*.swp,*.bak

" Snytastic stuff
function! ToggleErrors()
    let old_last_winnr = winnr('$')
    lclose
    if old_last_winnr == winnr('$')
        " Nothing was closed, open syntastic error location panel
        Errors
    endif
endfunction

" syntastic stuff
nnoremap <leader>e :<C-u>call ToggleErrors()<CR>
nnoremap <leader>l :lnext<CR>
nnoremap <leader>h :lprev<CR>
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_c_checkers = ["make"]
let g:syntastic_py_checkers = ["python3"]
let g:syntastic_cpp_checkers = ["make"]
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsUsePythonVersion = 3
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsListSnippets="<c-tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"
let g:UltiSnipsListSnippets="<Ctrl-l>"

" for devicons
set encoding=UTF-8
set guifont=Ubuntu\ Mono\ Nerd\ Font\ 11

colorscheme gruvbox
set bg=dark
