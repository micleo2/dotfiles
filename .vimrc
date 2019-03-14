"""""""""""""""""""""""""""""""""""""
" Michael Leon Vimrc configuration
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
Plugin 'airblade/vim-gitgutter'
Plugin 'majutsushi/tagbar'
Plugin 'universal-ctags/ctags'
Plugin 'tomtom/tcomment_vim'
Plugin 'scrooloose/syntastic'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'bergercookie/vim-debugstring'

" for react
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'

" React code snippets
Plugin 'epilande/vim-react-snippets'

" textobjects
Plugin 'kana/vim-textobj-user'
Plugin 'kana/vim-textobj-indent'

" Themes
Plugin 'ryanoasis/vim-devicons'

call vundle#end()            " required
filetype plugin on    " required
filetype plugin indent on    " required
"""" END Vundle Configuration


"""""""""""""""""""""""""""""""""""""
" Configuration Section
"""""""""""""""""""""""""""""""""""""
augroup basic_settings
  " set space as leader!!
  map <space> <leader>

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

  " change buffers without saving
  set hidden

  " Always display the status line
  set laststatus=2

  " Enable highlighting of the current line
  set cursorline

  " react snippets are also available in .js files
  let g:jsx_ext_required = 0

  " left moves past newline
  set whichwrap+=<,>,h,l,[,]
augroup end

" activate relative numbers in windows spawned by plugins
augroup rel_numbers
  " Tagbar
  let g:tabgar_autofocus=1
  let g:tagbar_show_linenumbers = -1
  "
  " enable line numbers
  let NERDTreeShowLineNumbers=1
  autocmd FileType nerdtree setlocal relativenumber
augroup end

"""""""""""""""""""""""""""""""""""""
" Mappings configurationn
"""""""""""""""""""""""""""""""""""""
augroup mappings
  map <C-x> :NERDTreeToggle<CR>
  map <C-t> :TagbarToggle<CR>
  map <C-g> :GitGutterAll<CR>
  nnoremap <leader>c :!ctags -R<CR>
  nnoremap <leader>j :tjump /
  nnoremap <leader>m :CtrlPTag<CR>

  " No ARRRROWWS!!!!
  nnoremap <Up>    :resize +2<CR>
  nnoremap <Down>  :resize -2<CR>
  nnoremap <Left>  :vertical resize +2<CR>
  nnoremap <Right> :vertical resize -2<CR>

  "
  " print helper in insert mode
  inoremap <C-l> <ESC>yiwea=#{<C-r>"}

  " set b/l to go to begin or end of line
  nnoremap <leader>b ^
  nnoremap <leader>l $

  " source current file easily
  nnoremap <leader>s <ESC>:source<Space>%<CR>
  "
  " make o turn off highlight
  nnoremap <leader>o <ESC>:noh<CR>

  " this is for easy buffer access
  nnoremap gb :ls<CR>:b<Space>

  " Syntastic toggle
  nnoremap <leader>e :<C-u>call ToggleErrors()<CR>

  " ctrl b gets caught by tmux, so use ctrl-h instead
  nnoremap <C-h> <C-b>
  nnoremap <C-b> <Nop>

  " re-purpose pgup and pgdwn to more useful commands
  nnoremap <PageUp> <ESC>:bnext<CR>
  nnoremap <PageDown> <ESC>:bprev<CR>
augroup end

augroup pending
  " operator pending movements
  " make in( behave like the text object i"
  onoremap in( :<c-u>normal! f(vi(<cr>
  " operate inside last pair of parenthesis
  onoremap il( :<c-u>normal! F)vi(<cr>
  " textobject for underscore
  onoremap i_ :<c-u>execute "normal! /_\\\|)\\\|,\\\|\\s\rhvNl" \| set nohlsearch<cr>
  onoremap a_ :<c-u>execute "normal! /_\\\|)\\\|,\\\|\\s\rhvN" \| set nohlsearch<cr>
  O
  " set b/l to go to begin or end of line
  onoremap <leader>b ^
  onoremap <leader>l $
augroup end

augroup styling
  " for devicons
  set encoding=UTF-8
  set guifont=Ubuntu\ Mono\ Nerd\ Font\ 11

  colorscheme gruvbox
  set bg=dark
augroup end

" Snytastic stuff
function! ToggleErrors()
    let old_last_winnr = winnr('$')
    lclose
    if old_last_winnr == winnr('$')
        " Nothing was closed, open syntastic error location panel
        Errors
    endif
endfunction

let g:syntastic_c_checkers = ["make"]
let g:syntastic_python_checkers = ["python3"]
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_cpp_checkers = ["make"]
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
