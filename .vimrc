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
augroup mappings
  nnoremap <C-x> :NERDTreeToggle<CR>
  nnoremap <C-t> :TagbarToggle<CR>
  nnoremap <C-g> :GitGutterAll<CR>
  nnoremap <leader>c :!ctags -R<CR>
  nnoremap <leader>g :!gotags -R . > tags<CR>
  nnoremap <leader>j :tjump /
  nnoremap <leader>m :CtrlPTag<CR>

  " No ARRRROWWS!!!!
  nnoremap <Up>    :resize +2<CR>
  nnoremap <Down>  :resize -2<CR>
  nnoremap <Left>  :vertical resize +2<CR>
  nnoremap <Right> :vertical resize -2<CR>

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

  " Syntastic toggle
  nnoremap <leader>e :<C-u>call ToggleErrors()<CR>

  " ctrl b gets caught by tmux, so use ctrl-k instead
  nnoremap <C-k> <C-b>
  vnoremap <C-k> <C-b>
  
  " ctrl f gets caught by tmux, so use ctrl-j instead
  nnoremap <C-j> <C-f>

  " re-purpose pgup and pgdwn to more useful commands
  nnoremap <PageUp> <ESC>:bnext<CR>
  nnoremap <PageDown> <ESC>:bprev<CR>

  " make new lines while staying where you are
  nnoremap <leader>i mlo<ESC>`l
  nnoremap <leader>I mlO<ESC>`l

  " surround current line with a newlines above and below
  nnoremap <leader>s mlO<ESC>jo<ESC>`l

  " Re-order lines
  nnoremap J :let c=col(".")<CR>:execute "normal! ddp" . c . "\|"<CR>
  nnoremap K :let c=col(".")<CR>:execute "normal! ddkP" . c . "\|"<CR>

  " Re-order lines while staying in visual mode
  vnoremap J <ESC>:execute "normal! gvdpV" . (line("'>") - line("'<")) ."j"<CR>
  vnoremap K <ESC>:execute "normal! gvdkPV" . (line("'>") - line("'<")) ."j"<CR>
  " using the move command is slower for some reason
  " vnoremap J :m '>+1<CR>gv=gv

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

  nnoremap Q :q<CR>

  nnoremap gy mlyyp`ljmlk:TComment<CR>`l
augroup tmux
  " rerun the last command in the rightmost pane
  nnoremap <Leader>tR :silent !tmux send-keys -t right "Up" C-m <CR> <C-l>
  " rerun the last command, leave fullscreen first
  nnoremap <Leader>tr :silent !tmux resize-pane -Z<CR> :silent !tmux send-keys -t right "Up" C-m <CR> <C-l>
  " like tr but a 'force run' -- run Ctrl-C first
  nnoremap <Leader>tf :silent !tmux resize-pane -Z<CR> :silent !tmux send-keys -t right C-c<CR>:silent !tmux send-keys -t right "Up" C-m <CR> <C-l>
  " like tR but a 'force run' -- run Ctrl-C first
  nnoremap <Leader>tF :silent !tmux send-keys -t right C-c<CR>:silent !tmux send-keys -t right "Up" C-m <CR> <C-l>

  " rerun the last command in the rightmost pane, leave fullscreen and exit insert mode and save file
  inoremap jk <ESC>:w<CR>:silent !tmux resize-pane -Z<CR> :silent !tmux send-keys -t right "Up" C-m <CR> <C-l>
  " rerun the last command in the rightmost pane, and exit insert mode and save file
  inoremap jK <ESC>:w<CR>:silent !tmux send-keys -t right "Up" C-m <CR> <C-l>

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
  " operator pending movements
  " make in( behave like the text object i"
  onoremap in( :<c-u>normal! f(vi(<cr>
  onoremap in[ :<c-u>normal! f[vi[<cr>
  " operate inside last pair of parenthesis
  onoremap il( :<c-u>normal! F)vi(<cr>
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
