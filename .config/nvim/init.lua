--- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- *** Basic settings ***
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- Line numbers
vim.o.number = true
vim.o.relativenumber = true
vim.o.ruler = true
-- Case insensitive until one uppercase is typed
vim.o.ignorecase = true
vim.o.smartcase = true
-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'
-- Decrease update time
vim.o.updatetime = 250
-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300
-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true
-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'
-- Show which line your cursor is on
vim.o.cursorline = true
-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true
-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- enable 24-bit colour
vim.opt.termguicolors = true

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- *** Startup screen ***
    'mhinz/vim-startify',

     -- *** Utils ***
    'nvim-lua/plenary.nvim',

    -- *** Fuzzy finder ***
    {
      "folke/snacks.nvim",
      opts = {
        picker = {},
        image = {},
      },
      keys = {
        -- Top Pickers & Explorer
        { "<C-p>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
        { "gn", function() Snacks.picker.buffers() end, desc = "Buffers" },
        { "<C-g>", function() Snacks.picker.grep() end, desc = "Grep" },
        -- { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
        -- { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
        { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
        -- LSP
        { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
        { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
        { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
        { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
        { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
        { "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "C[a]lls Incoming" },
        { "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "C[a]lls Outgoing" },
        { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
        { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
      },
    },

    -- *** Treesitter ***
    {
      'nvim-treesitter/nvim-treesitter',
      opts = {
        ensure_installed = { "lua", "cpp", "c", "rust", "python", "javascript" },  -- List of parsers to install
	highlight = {
	  enabled = true,
	}
      },
    },
    'nvim-treesitter/nvim-treesitter-textobjects',

    -- *** Diagnostics ***
    'folke/trouble.nvim',

    -- *** File explorer ***
    {
      'nvim-tree/nvim-tree.lua',
      lazy = false,
      dependencies = {
        "nvim-tree/nvim-web-devicons",
      },
      config = function()
        require("nvim-tree").setup({})
      end,
      keys = {
        { "<C-x>", function() vim.cmd("NvimTreeFindFileToggle") end, desc = "Toggle file explorer" },
      }
    },

    -- *** UI upgrades ***
    {
      "folke/noice.nvim",
      event = "VeryLazy",
      opts = {},
      dependencies = {
        "MunifTanjim/nui.nvim",
        "rcarriga/nvim-notify",
        }
    },

    -- *** Text editing ***
    'tpope/vim-surround',
    'tomtom/tcomment_vim',
    'tommcdo/vim-exchange',

    -- *** motion ***
    'ggandor/leap.nvim',

    -- *** replacing ***
    'nvim-pack/nvim-spectre',

    -- *** VersionControl info per line ***
    'mhinz/vim-signify',

    -- *** Styling ***
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      opts = {
	flavor = "mocha",
        auto_integrations = true
      }
    },
    -- lualine
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      opts = {
        options = {theme = "catppuccin"},
        sections = {
          lualine_x = {'filename'},
          lualine_c = {
            {"navic", color_correction = nil, navic_opts = nil},
          }
        }
      }
    }

  },
})

-- colorscheme
vim.cmd.colorscheme "catppuccin"

-- *** Vanilla key mappings ***
-- Q for easy quitting
vim.keymap.set('n', 'Q', ':q!<CR>')
-- esc in normal mode to turn off search highlight
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>')
-- No ARRRROWWS!!!!
vim.keymap.set('n', '<Up>', ':resize +4<CR>')
vim.keymap.set('n', '<Down>', ':resize -4<CR>')
vim.keymap.set('n', '<Left>', ':vertical resize +4<CR>')
vim.keymap.set('n', '<Right>', ':vertical resize -4<CR>')
-- Better window keybinds
vim.keymap.set('n', '<leader>h', '<C-w>h')
vim.keymap.set('n', '<leader>j', '<C-w>j')
vim.keymap.set('n', '<leader>J', '<C-w>s<C-w>j')
vim.keymap.set('n', '<leader>k', '<C-w>k')
vim.keymap.set('n', '<leader>l', '<C-w>l')
vim.keymap.set('n', '<leader>L', '<C-w>v<C-w>l')
-- search in visual mode
vim.keymap.set('v', '//', 'y/<C-R>"<CR>')
-- set b/l to go to begin or end of line
vim.keymap.set('n', '<C-h>', '^')
vim.keymap.set('n', '<C-l>', '$')
vim.keymap.set('v', '<C-h>', '^')
vim.keymap.set('v', '<C-l>', '$')
-- ctrl b gets caught by tmux, so use ctrl-k/f instead
vim.keymap.set('n', '<C-k>', '<C-b>')
vim.keymap.set('v', '<C-k>', '<C-b>')
-- U reverts file to last save
vim.keymap.set('n', 'U', ':e!<CR>')
-- edit init.vim file
vim.keymap.set('n', 'ze', ':e ~/.config/nvim/init.vim<CR>')
vim.keymap.set('n', 'zs', ':e ~/.zshrc<CR>')
-- have Y mimic D and C etc
vim.keymap.set('n', 'Y', 'y$')
-- source current file easily
vim.keymap.set('n', '<leader>S', '<ESC>:source<Space>%<CR>')
-- I use this specific directory a lot
vim.keymap.set('n', 'gl', ':e ~/tests/')
-- make new lines while staying where you are
vim.keymap.set('n', '<leader>i', 'mlo<ESC>`l')
vim.keymap.set('n', '<leader>I', 'mlO<ESC>`l')
-- surround current line with a newlines above and below
vim.keymap.set('n', '<leader>s', 'mlO<ESC>jo<ESC>`l')
-- -- Re-order lines
-- vim.keymap.set('n', 'J', ':let c=col(\".\")<CR>:execute \"normal! ddp\" . c . \"\|\"<CR>')
-- vim.keymap.set('n', 'K', ':let c=col(\".\")<CR>:execute \"normal! ddkP\" . c . \"\|\"<CR>')
-- replace current word and leave dot more useful
vim.keymap.set('n', '<leader>r', 'ml*`lcgn')
-- vim.keymap.set('n', '<leader>g', 'diw"0P')
-- vim.keymap.set('n', '<leader>G', 'diW"0P')
-- get quick access to all unbinded keys
vim.keymap.set('n', '<leader>n', ':norm! ')
-- save files quickly.
vim.keymap.set('n', '<leader>w', ':up<CR>')
vim.keymap.set('n', '<leader>W', ':wa<CR>')
-- move to true end/begin of file.
vim.keymap.set('n', 'G', 'G$')
vim.keymap.set('n', 'gg', 'gg^')
-- quickfix list navigation
vim.keymap.set('n', 'gj', ':cnext<CR>')
vim.keymap.set('n', 'gk', ':cprev<CR>')

