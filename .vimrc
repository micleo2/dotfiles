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
Plugin 'tpope/vim-fugitive'
Plugin 'tommcdo/vim-exchange'

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

  " tab settings
  set smartindent   " Do smart autoindenting when starting a new line
  set shiftwidth=2  " Set number of spaces per auto indentation
  set expandtab     " When using <Tab>, put spaces instead of a <tab> character

  " good to have for consistency
  set tabstop=2   " Number of spaces that a <Tab> in the file counts for
  set smarttab    " At <Tab> at beginning line inserts spaces set in shiftwidth

  " change buffers without saving
  set hidden

  " Always display the status line
  set laststatus=2

  " Enable highlighting of the current line
  set cursorline

  " react snippets are also available in .js files
  let g:jsx_ext_required = 0

  " left/right moves past newline
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
augroup plugin-mappings
  nnoremap <C-x> :NERDTreeToggle<CR>
  nnoremap <C-t> :TagbarToggle<CR>
  nnoremap <C-g> :GitGutterAll<CR>
  nnoremap <leader>m :CtrlPTag<CR>
  nnoremap gs :Gstatus<CR>
  nnoremap <leader>d :Gdiff<CR>
  
  " Syntastic toggle
  nnoremap <leader>e :<C-u>call ToggleErrors()<CR>

  " generate ctags file
  nnoremap <leader>c :!ctags -R<CR>
  nnoremap <leader>g :!gotags -R . > tags<CR>

  nnoremap gH mlyyp`ljmlk:TComment<CR>`l
augroup end

" Note: the l marker/register is treated as scratch space for many mappings
augroup vanilla-mappings
  " No ARRRROWWS!!!!
  nnoremap <Up>    :resize +4<CR>
  nnoremap <Down>  :resize -4<CR>
  nnoremap <Left>  :vertical resize +4<CR>
  nnoremap <Right> :vertical resize -4<CR>

  " search in visual mode
  vnoremap // y/<C-R>"<CR>

  " set b/l to go to begin or end of line
  nnoremap <leader>b ^
  nnoremap <leader>l $
  vnoremap <leader>b ^
  vnoremap <leader>l $

  " U reverts file to last save
  nnoremap U :e!<CR>

  " have Y mimic D and C etc
  nnoremap Y y$

  " source current file easily
  nnoremap <leader>S <ESC>:source<Space>%<CR>

  " make o turn off highlight
  nnoremap <leader>o <ESC>:noh<CR>
  " make O turn on highlight
  nnoremap <leader>O <ESC>:set hls<CR>

  " this is for easy buffer access
  nnoremap gb :ls<CR>:b<Space>

  " ctrl b gets caught by tmux, so use ctrl-k instead
  nnoremap <C-k> <C-b>
  vnoremap <C-k> <C-b>
  
  " re-purpose pgup and pgdwn to more useful commands
  nnoremap <PageUp> <ESC>:bnext<CR>
  nnoremap <PageDown> <ESC>:bprev<CR>

  " make new lines while staying where you are
  nnoremap <leader>i mlo<ESC>`l
  nnoremap <leader>I mlO<ESC>`l

  " surround current line with a newlines above and below
  nnoremap <leader>s mlO<ESC>jo<ESC>`li

  " Re-order lines
  nnoremap J :let c=col(".")<CR>:execute "normal! ddp" . c . "\|"<CR>
  nnoremap K :let c=col(".")<CR>:execute "normal! ddkP" . c . "\|"<CR>

  " Re-order lines while staying in visual mode
  vnoremap J <ESC>:execute "normal! gvdpV" . (line("'>") - line("'<")) ."j"<CR>
  vnoremap K <ESC>:execute "normal! gvdkPV" . (line("'>") - line("'<")) ."j"<CR>

  " Shift text around in character visual mode, only use with one line selection
  " vnoremap L <ESC>:execute "normal! gvdpv" . (col("'>") - col("'<")) ."h"<CR>
  " vnoremap H <ESC>:execute "normal! gvdhPv" . (col("'>") - col("'<")) ."h"<CR>

  " swap ` and '
  nnoremap ' `
  nnoremap ` '

  " search current word but not move your cursor position
  nnoremap S ml*`l

  " replace current word and leave dot more useful
  nnoremap <leader>r ml*`lcgn
  nnoremap <leader>R ml*`lcgN

  " Q for easy quitting
  nnoremap Q :q<CR>

  " copy current line to next line and keep cursor on same column
  nnoremap gh mlyyp`lj

  " get quick access to all unbinded keys
  nnoremap <leader>n :norm! 

  " have deletes that write into 0 register, so it's like 
  " you're yanking what you're about to delete
  nnoremap gy "0d
  nnoremap gY "0D

  inoremap jk <ESC>:w<CR>
augroup end

augroup tmux
  " mainly for Haskell's ghci
  nnoremap <Leader>tl :silent !tmux send-keys -t right "C-l" <CR> <C-l><C-l>
  nnoremap <Leader>hr :silent !tmux send-keys -t right ":reload" C-m <CR> <C-l><C-l>

  " rerun the last command in the rightmost pane
  nnoremap <Leader>tR :silent !tmux send-keys -t right "Up" C-m <CR> <C-l>
  " rerun the last command, leave fullscreen first
  nnoremap <Leader>tr :silent !tmux resize-pane -Z<CR> :silent !tmux send-keys -t right "Up" C-m <CR> <C-l>
  " like tr but a 'force run' -- run Ctrl-C first
  nnoremap <Leader>tf :silent !tmux resize-pane -Z<CR> :silent !tmux send-keys -t right C-c<CR>:silent !tmux send-keys -t right "Up" C-m <CR> <C-l>
  " like tR but a 'force run' -- run Ctrl-C first
  nnoremap <Leader>tF :silent !tmux send-keys -t right C-c<CR>:silent !tmux send-keys -t right "Up" C-m <CR> <C-l>

  " " rerun the last command in the rightmost pane, leave fullscreen and exit insert mode and save file
  " inoremap jk <ESC>:w<CR>:silent !tmux resize-pane -Z<CR> :silent !tmux send-keys -t right "Up" C-m <CR> <C-l>
  " " rerun the last command in the rightmost pane, and exit insert mode and save file
  " inoremap jK <ESC>:w<CR>:silent !tmux send-keys -t right "Up" C-m <CR> <C-l>

  " kill the program running in the last active tmux pane
  nnoremap <Leader>tc :silent !tmux send-keys -t \\! C-c <CR> <C-l>

  " send current line to last active pane -- VERY BUGGY
  nnoremap <Leader>tp :exe "!tmux send-keys -t \\! \"" . getline(".") . "\" C-m" <CR> <C-l>
  " send selected visual area to last active tmux pane -- VERY BUGGY
  vnoremap <Leader>tp <ESC>:exe "!tmux send-keys -t \\! \"" . @* . "\" C-m" <CR> <C-l>

  " Launch a python shell interpreter in last active pane
  nnoremap <Leader>tip :silent !tmux send-keys -t \\! "python3.6" C-m "import numpy as np" C-m<CR> <C-l> :silent !tmux select-pane -t \\!<CR>
  " Launch a javascript shell interpreter in last active pane
  nnoremap <Leader>tij :silent !tmux send-keys -t \\! "node" C-m <CR> <C-l> :silent !tmux select-pane -t \\!<CR>
  " Launch a javascript shell interpreter in last active pane
  nnoremap <Leader>tir :silent !tmux send-keys -t \\! "irb" C-m <CR> <C-l> :silent !tmux select-pane -t \\!<CR>
augroup end

augroup pending
  " make I" move backwards
  onoremap I" :<c-u>norm! F"vi"<cr>

  " operator pending movements
  " make i) etc behave like the text object i"
  onoremap i) :<c-u>norm! f(vi(<cr>
  onoremap i] :<c-u>norm! f[vi[<cr>
  " complements of the above but backwards
  onoremap I) :<c-u>norm! F)vi(<cr>
  onoremap I] :<c-u>norm! F]vi[<cr>
  " textobject for underscore
  onoremap i_ :<c-u>execute "normal! /_\\\|)\\\|,\\\|\\s\rhvNl" \| set nohlsearch<cr>
  onoremap a_ :<c-u>execute "normal! /_\\\|)\\\|,\\\|\\s\rhvN" \| set nohlsearch<cr>
  
  " set b/l to go to begin or end of line
  onoremap <leader>b ^
  onoremap <leader>l $
augroup end

augroup styling
  " for devicons
  set encoding=UTF-8
  set guifont=Ubuntu\ Mono\ Nerd\ Font\ 11
  let g:airline_powerline_fonts = 1

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

let g:syntastic_go_checkers = ["govet"]
let g:syntastic_c_checkers = ["make"]
let g:syntastic_python_checkers = ["python3"]
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_cpp_checkers = ["make"]
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
