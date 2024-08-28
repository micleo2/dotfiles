call plug#begin(expand('~/.vim/bundle'))

" start screen
Plug 'mhinz/vim-startify'

" LSP / file semantics
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'SmiteshP/nvim-navic'
Plug 'ray-x/lsp_signature.nvim' " show inlay hints for function arguments
Plug 'p00f/clangd_extensions.nvim' " show inlay hints for types
Plug 'stevearc/aerial.nvim' " tagbar-like for lsp/treesitter
Plug 'RRethy/vim-illuminate' " highlight token under cursor using lsp/TS/regex

" completion
let g:coq_settings = { 'auto_start': v:true , 'keymap.jump_to_mark': '<C-j>'}
Plug 'ms-jpq/coq_nvim', {'branch': 'coq'} "
Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'}

" lsp diagnostic
Plug 'folke/trouble.nvim'

" debugging
Plug 'andrewferrier/debugprint.nvim'

" File navigation
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

" File explorer
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'

" Text editing
Plug 'tpope/vim-surround'
Plug 'tomtom/tcomment_vim'
Plug 'tommcdo/vim-exchange'

" textobjects
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-indent'
Plug 'nvim-treesitter/nvim-treesitter-textobjects'

" motion
Plug 'ggandor/leap.nvim'

" buffer management
Plug 'ThePrimeagen/harpoon'

" styling
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'nvim-lualine/lualine.nvim'
Plug 'kyazdani42/nvim-web-devicons'

" searching
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
Plug 'jackysee/telescope-hg.nvim' " gives hg-specifc pickers for telescope

" replacing
Plug 'nvim-pack/nvim-spectre'

" VersionControl info per line
Plug 'mhinz/vim-signify'

" tidal cycles plugins
Plug 'tidalcycles/vim-tidal'
let g:tidal_target = "terminal"

if filereadable(expand("~/.config/nvim/work-plugins.vim"))
  source ~/.config/nvim/work-plugins.vim
endif

call plug#end()

" LSP config
lua << EOF
local navic = require("nvim-navic")
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', '<space>cn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<space>F', '<cmd>lua vim.lsp.buf.format()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua require("trouble").next({skip_groups = true, jump = true})<CR>', opts)
  local caps = client.server_capabilities
  if caps.documentSymbolProvider then
    navic.attach(client, bufnr)
  end
  -- if client.server_capabilities.inlayHintProvider then
  --   vim.lsp.buf.inlay_hint(bufnr, true)
  -- end
end

require("debugprint").setup({
  create_keymaps = false,
  create_commands = false
})
vim.keymap.set("n", "<Leader>dc", function()
    return require('debugprint').debugprint({variable = true, display_counter=false})
end, {
    expr = true,
})
vim.keymap.set("n", "<Leader>dC", function()
    return require('debugprint').debugprint({variable = true, display_counter=false, above=true})
end, {
    expr = true,
})
vim.keymap.set("v", "<Leader>dc", function()
    return require('debugprint').debugprint({variable = true, display_counter=false})
end, {
    expr = true,
})
vim.keymap.set("v", "<Leader>dC", function()
    return require('debugprint').debugprint({variable = true, display_counter=false, above=true})
end, {
    expr = true,
})
vim.keymap.set("n", "<Leader>dp", function()
    return require('debugprint').debugprint()
end, {
    expr = true,
})

-- C++ LSP
local lsp = require'lspconfig'
local coq = require "coq"

-- minimal setup
lsp.clangd.setup{
  on_attach=on_attach,
  coq.lsp_ensure_capabilities{},
  -- cmd={vim.fn.expand("$HOME/clang/clangd_17.0.3/bin/clangd")}
  cmd={"/home/mike/clang/clangd_18.1.3/bin/clangd"}
}

-- Rust LSP
lsp.rust_analyzer.setup{
  on_attach=on_attach,
  coq.lsp_ensure_capabilities{},
}

-- Setup telescope. Disable previewing large files.
local actions = require('telescope.actions')
require('telescope').setup {
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
    }
  },
  defaults = {
    preview = {
      filesize_hook = function(filepath, bufnr, opts)
        local max_bytes = 10000
        local cmd = {"head", "-c", max_bytes, filepath}
        require('telescope.previewers.utils').job_maker(cmd, bufnr, opts)
      end
    },
    mappings = {
      n = {
        ["<C-q>"]   = actions.smart_send_to_qflist + actions.open_qflist
      }
    }
  }
}

-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')
-- Load the hg pickers.
require('telescope').load_extension('hg')

-- File explorer
require("nvim-tree").setup()

-- navic/lua
require("lualine").setup({
  options = {theme = "catppuccin"},
  sections = {
    lualine_x = {'filename'},
    lualine_c = {
      {"navic", color_correction = nil, navic_opts = nil},
    }
  }
})

-- lsp_signature
require "lsp_signature".setup()

-- treesitter
require'nvim-treesitter.configs'.setup {
  ensure_installed = {"lua", "cpp", "c", "rust", "python", "javascript"},
  sync_install = false,
  highlight = {
    enable = true
  },
}

-- nvim-treesitter-textobjects
require'nvim-treesitter.configs'.setup {
  textobjects = {
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]]"] = "@function.outer",
        ["]l"] = "@class.outer",
        ["]b"] = "@block.outer",
      },
      goto_next_end = {
        ["]["] = "@function.outer",
        ["]L"] = "@class.outer",
        ["]B"] = "@block.outer",
      },
      goto_previous_start = {
        ["[["] = "@function.outer",
        ["[l"] = "@class.outer",
        ["[b"] = "@block.outer",
      },
      goto_previous_end = {
        ["[]"] = "@function.outer",
        ["[L"] = "@class.outer",
        ["[B"] = "@block.outer",
      },
    },
    select = {
      enable = true,
      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
      },
    },
  },
}

-- file overview
require'aerial'.setup{}

-- lsp error diagnostics
require("trouble").setup{}

-- colorscheme
require("catppuccin").setup {
  integration = {
    telescope = false
  }
}

-- highlight word under cursor. Wait 500ms (0.5s) to turn on highlight.
require('illuminate').configure({delay = 500})
-- make sure color matches current colorscheme
local hl_col = require("catppuccin.palettes").get_palette("mocha").crust
vim.api.nvim_set_hl(0, 'IlluminatedWordText', {bg=hl_col})
vim.api.nvim_set_hl(0, 'IlluminatedWordRead', {bg=hl_col})
vim.api.nvim_set_hl(0, 'IlluminatedWordWrite', {bg=hl_col})

-- setup motion keybindings.
require('leap').add_default_mappings(true)

EOF

if filereadable(expand("~/.config/nvim/work-init.vim"))
  source ~/.config/nvim/work-init.vim
endif

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
  " set smartindent   " Do smart autoindenting when starting a new line
  set tabstop=2
  set shiftwidth=2
  set expandtab

  " change buffers without saving
  set hidden

  " Always display the status line
  set laststatus=2

  " Enable highlighting of the current line
  set cursorline

  " left/right moves past newline
  set whichwrap+=<,>,h,l,[,]

  " restore cursor to last saved position
  autocmd BufReadPost * silent! normal! g`"zv

  " case insensitive until one uppercase is typed
  set ignorecase smartcase
augroup end

augroup terminal_emulator
  :tnoremap <C-j> <C-\><C-n>
  autocmd TermOpen * setlocal nonumber norelativenumber
augroup end

augroup plugin-mappings
  " copy current line to next line and keep cursor on same column
  nnoremap gH mlyyp`ljmlk:TComment<CR>`l
  nnoremap gh mlyyp`lj

  " TELESCOPE SECTION
  " Ctrl-p is file finder.
  nnoremap <C-p> <cmd>Telescope find_files<cr>
  " Ctrl-g is grep.
  nnoremap <C-g> <cmd>Telescope live_grep<cr>
  nnoremap gw yiw:Telescope live_grep<cr><C-r>"<ESC>
  nnoremap gW yiW<cmd>Telescope live_grep<cr><C-r>"<ESC>
  nnoremap gn <cmd>Telescope buffers<cr>
  nnoremap gd <cmd>Telescope lsp_definitions<CR><ESC><ESC>
  nnoremap gD <cmd>Telescope lsp_type_definitions<CR><ESC><ESC>
  nnoremap gf <C-w>v<C-w>l<cmd>Telescope lsp_definitions<CR><ESC><ESC>
  nnoremap <leader>fr <cmd>Telescope lsp_references<cr><ESC><ESC>
  nnoremap <leader>ff <cmd>Telescope lsp_document_symbols<cr>
  nnoremap <leader>ft <cmd>Telescope treesitter<cr>
  nnoremap <leader>fg :lua require('telescope.builtin').live_grep({grep_open_files=true})<CR>

  " spawn aerial overview of the file on the right pane
  nnoremap <C-d> :AerialToggle<CR>

  " Toggle file explorer
  nnoremap <C-x> :NvimTreeFindFileToggle<CR>

  " spawn LSP diagnostic window
  nnoremap <leader>xx <cmd>TroubleToggle<cr>

  " switch between header/source file
  nnoremap gs :ClangdSwitchSourceHeader<CR>

  " vim-signify default updatetime 4000ms is not good for async update
  set updatetime=100

  " harpoon
  nnoremap <leader>aa :lua require("harpoon.mark").add_file()<CR>
  nnoremap <leader>ah :lua require("harpoon.ui").toggle_quick_menu()<CR>
  nnoremap <leader>1 :lua require("harpoon.ui").nav_file(1)<CR>
  nnoremap <leader>2 :lua require("harpoon.ui").nav_file(2)<CR>
  nnoremap <leader>3 :lua require("harpoon.ui").nav_file(3)<CR>
  nnoremap <leader>4 :lua require("harpoon.ui").nav_file(4)<CR>
  nnoremap <leader>5 :lua require("harpoon.ui").nav_file(5)<CR>

  " toggle file explorer
augroup end

" Note: the l marker/register is treated as scratch space for many mappings
augroup vanilla-mappings
  " No ARRRROWWS!!!!
  nnoremap <Up>    :resize +4<CR>
  nnoremap <Down>  :resize -4<CR>
  nnoremap <Left>  :vertical resize +4<CR>
  nnoremap <Right> :vertical resize -4<CR>

  nnoremap <leader>h <C-w>h
  nnoremap <leader>j <C-w>j
  nnoremap <leader>J <C-w>s<C-w>j
  nnoremap <leader>k <C-w>k
  nnoremap <leader>l <C-w>l
  nnoremap <leader>L <C-w>v<C-w>l

  " search in visual mode
  vnoremap // y/<C-R>"<CR>

  " set b/l to go to begin or end of line
  nnoremap <C-h> ^
  nnoremap <C-l> $
  vnoremap <C-h> ^
  vnoremap <C-l> $

  " ctrl b gets caught by tmux, so use ctrl-k/f instead
  nnoremap <C-k> <C-b>
  vnoremap <C-k> <C-b>

  " U reverts file to last save
  nnoremap U :e!<CR>

  " edit init.vim file
  nnoremap ze :e ~/.config/nvim/init.vim<CR>
  nnoremap zs :e ~/.zshrc<CR>

  " have Y mimic D and C etc
  nnoremap Y y$

  " source current file easily
  nnoremap <leader>S <ESC>:source<Space>%<CR>

  " make o turn off highlight
  nnoremap <leader>o <ESC>:noh<CR>
  " make O turn on highlight
  nnoremap <leader>O <ESC>:set hls<CR>

  " I use this specific directory a lot
  nnoremap gl :e ~/tests/

  " make new lines while staying where you are
  nnoremap <leader>i mlo<ESC>`l
  nnoremap <leader>I mlO<ESC>`l

  " surround current line with a newlines above and below
  nnoremap <leader>s mlO<ESC>jo<ESC>`l

  " Re-order lines
  nnoremap J :let c=col(".")<CR>:execute "normal! ddp" . c . "\|"<CR>
  nnoremap K :let c=col(".")<CR>:execute "normal! ddkP" . c . "\|"<CR>

  " replace current word and leave dot more useful
  nnoremap <leader>r ml*`lcgn
  nnoremap <leader>R <cmd>lua require("spectre").toggle()<CR>
  nnoremap <leader>g diw"0P
  nnoremap <leader>G diW"0P

  " Q for easy quitting
  nnoremap Q :q<CR>

  " get quick access to all unbinded keys
  nnoremap <leader>n :norm! 

  " save files quickly.
  nnoremap <leader>w :w<CR>
  nnoremap <leader>W :wa<CR>

  " move to true end/begin of file.
  nnoremap G G$
  nnoremap gg gg^

  " quickfix list navigation
  nnoremap gj :cnext<CR>
  nnoremap gk :cprev<CR>

  nnoremap <leader>e :%s///g<Left><Left><Left>
augroup end

augroup per-language-mappings
  " faster & more reliable than having to go through snippets.
  autocmd FileType javascript     nnoremap <buffer> <leader>p oprint("");<Left><Left><Left>
  autocmd FileType javascript     nnoremap <buffer> <leader>P Oprint("");<Left><Left><Left>
augroup end

augroup tmux
  " zoom out and rerun the last command
  nnoremap <Leader>tr :w<CR>:silent !~/scripts/tmux/zoom-out.sh<CR>:silent !tmux send-keys -t \\! "Up" C-m <CR> <C-l>
  inoremap jk <ESC>:w<CR>:silent !~/scripts/tmux/zoom-out.sh<CR>:silent !tmux send-keys -t \\! "Up" C-m <CR> <C-l>
  " like tr but a 'force run' -- run Ctrl-C first
  nnoremap <Leader>tf :w<CR>:silent !~/scripts/tmux/zoom-out.sh<CR> :silent !tmux send-keys -t \\! C-c<CR>:silent !tmux send-keys -t \\! "Up" C-m <CR> <C-l>
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
  syntax enable
  " colorscheme catppuccin-latte
  colorscheme catppuccin-mocha
  " set bg=dark
augroup end

