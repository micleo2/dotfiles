--- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
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
-- tab settings
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
-- change buffers without saving
vim.o.hidden = true
-- Show which line your cursor is on
vim.o.cursorline = true
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
-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true
-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- enable 24-bit colour
vim.opt.termguicolors = true

-- Helper function to be able to use vim.command easily from keymappings
-- This also has the added benefit of not triggering the cmdline UI.
local function vcmd(cmd)
  return function()
    vim.cmd(cmd)
  end
end

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
        { "<C-p>",      function() Snacks.picker.smart() end,                 desc = "Smart Find Files" },
        { "gn",         function() Snacks.picker.buffers() end,               desc = "Buffers" },
        { "<C-g>",      function() Snacks.picker.grep() end,                  desc = "Grep" },
        -- { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
        -- { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
        { "<leader>e",  function() Snacks.explorer() end,                     desc = "File Explorer" },
        -- LSP
        { "gd",         function() Snacks.picker.lsp_definitions() end,       desc = "Goto Definition" },
        { "gD",         function() Snacks.picker.lsp_declarations() end,      desc = "Goto Declaration" },
        { "gr",         function() Snacks.picker.lsp_references() end,        desc = "References",            nowait = true },
        { "gI",         function() Snacks.picker.lsp_implementations() end,   desc = "Goto Implementation" },
        { "gy",         function() Snacks.picker.lsp_type_definitions() end,  desc = "Goto T[y]pe Definition" },
        { "gai",        function() Snacks.picker.lsp_incoming_calls() end,    desc = "C[a]lls Incoming" },
        { "gao",        function() Snacks.picker.lsp_outgoing_calls() end,    desc = "C[a]lls Outgoing" },
        { "<leader>ss", function() Snacks.picker.lsp_symbols() end,           desc = "LSP Symbols" },
        { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
      },
    },

    -- *** LSP ***
    {
      "ms-jpq/coq.nvim",
      dependencies = { "ms-jpq/coq.artifacts", branch = "artifacts" },
      branch = "coq",
      build = ":COQdeps",
      init = function()
        vim.g.coq_settings = {
          auto_start = true,
          keymap = {
            jump_to_mark = '<C-j>'
          },
          display = {
            statusline = {
              helo = false,
            },
          },
        }
      end,
    },
    {
      "neovim/nvim-lspconfig",
      lazy = false,
      dependencies = { "ms-jpq/coq.nvim" },
      -- opts = {
      --   servers = {
      --     clangd = {
      --       cmd = { "clangd", "--header-insertion=never" },
      --     },
      --   },
      -- },
      keys = {
        { "gs",        vcmd("ClangdSwitchSourceHeader"),    desc = "Switch Source/Header (C/C++)" },
        { "<leader>F", function() vim.lsp.buf.format() end, desc = "LSP Format" },
      },
    },
    {
      "mason-org/mason.nvim",
      opts = {}
    },
    {
      "mason-org/mason-lspconfig.nvim",
      opts = {
        ensure_installed = { "clangd" },
      },
      dependencies = {
        "mason-org/mason.nvim",
        "neovim/nvim-lspconfig",
      },
    },
    -- tagbar-like for lsp/treesitter
    {
      'stevearc/aerial.nvim',
      opts = {},
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons"
      },
      keys = {
        { '<C-d>', vcmd('AerialToggle'), desc = 'Toggle Aerial view' },
      }
    },

    -- *** which key ***
    {
      'folke/which-key.nvim',
      event = 'VeryLazy',
      opts = {},
      keys = {
        {
          '<leader>?',
          function()
            require("which-key").show({ global = true })
          end,
          desc = 'Buffer Local Keymaps (which-key)',
        },
      },
    },

    -- *** Treesitter ***
    {
      'nvim-treesitter/nvim-treesitter',
      lazy = false,
      opts = {
        ensure_installed = { "lua", "cpp", "c", "rust", "python", "javascript" }, -- List of parsers to install
        highlight = {
          enabled = true,
        }
      },
    },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      dependencies = { "nvim-treesitter/nvim-treesitter" },
      config = function()
        require('nvim-treesitter.configs').setup {
          textobjects = {
            move = {
              enable = true,
              set_jumps = true, -- add to jumplist
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
                ["if"] = "@function.inner",
                ["af"] = "@function.outer",
                ["ia"] = "@parameter.inner",
                ["aa"] = "@parameter.outer",
                ["ik"] = "@block.inner",
                ["ak"] = "@block.outer",
                ["il"] = "@loop.inner",
                ["al"] = "@loop.outer",
                ["ii"] = "@conditional.inner",
                ["ai"] = "@conditional.outer",
              },
            },
            swap = {
              enable = true,
              swap_next = {
                ["<leader>a"] = "@parameter.inner",
              },
              swap_prev = {
                ["<leader>A"] = "@parameter.inner",
              },
            },
          },
        }
      end,
    },
    {
      'aaronik/treewalker.nvim',
      event = 'VeryLazy',
      dependencies = { "nvim-treesitter/nvim-treesitter" },
      opts = {},
      keys = {
        { 'gh', vcmd('Treewalker Left'),  desc = 'Treewalker move left' },
        { 'gj', vcmd('Treewalker Down'),  desc = 'Treewalker move down' },
        { 'gk', vcmd('Treewalker Up'),    desc = 'Treewalker move up' },
        { 'gl', vcmd('Treewalker Right'), desc = 'Treewalker move right' },
      },
    },

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
    'tommcdo/vim-exchange',
    {
      'tomtom/tcomment_vim',
      keys = {
        {
          "gH",
          function()
            vim.cmd("NvimTreeFindFileToggle")
          end,
          desc = "Duplicate line, leave behind commented out"
        },
        { "gH", "mlyyp`lj", desc = "Duplicate line, remember cursor" },
      }
    },

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
    -- visual indents
    {
      "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      opts = {},
    },
    -- lualine
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      opts = {
        options = { theme = "catppuccin" },
        sections = {
          lualine_b = {
            'branch',
            'diff',
            'diagnostics',
            function()
              local reg = vim.fn.reg_recording()
              if reg == "" then
                return ""
              else
                return "Recording @" .. reg
              end
            end,
            { "navic", color_correction = nil, navic_opts = nil },
          },
          lualine_c = {
            (function()
              local hg_diff_num = nil
              local last_update = 0
              local update_interval = 60 -- in seconds
              return function()
                local now = os.time()
                if not hg_diff_num or (now - last_update) > update_interval then
                  local ok, result = pcall(function()
                    local handle = io.popen('hg log --limit 1')
                    if handle == nil then
                      return nil
                    end
                    local output = handle:read("*a")
                    handle:close()
                    return output
                  end)
                  last_update = now
                  if ok and result and result ~= "" then
                    hg_diff_num = result:match("D%d%d%d%d%d%d%d%d") or ""
                  else
                    hg_diff_num = ""
                  end
                end
                if hg_diff_num ~= "" then
                  return hg_diff_num
                else
                  return ""
                end
              end
            end)()
          },
          lualine_x = { 'filename' },
        },
      }
    }
  },
})

-- colorscheme
vim.cmd.colorscheme "catppuccin"

-- *** Vanilla key mappings ***
-- Q for easy quitting
vim.keymap.set('n', 'Q', ':q!<CR>')
-- save files quickly.
vim.keymap.set('n', '<leader>w', vcmd('up'))
vim.keymap.set('n', '<leader>W', vcmd('wa'))
-- esc in normal mode to turn off search highlight
-- use cmd so that the cmdline prompt doesn't show briefly
vim.keymap.set('n', '<Esc>', vcmd('nohlsearch'))
-- No ARRRROWWS!!!!
vim.keymap.set('n', '<Up>', vcmd('resize +4'))
vim.keymap.set('n', '<Down>', vcmd('resize -4'))
vim.keymap.set('n', '<Left>', vcmd('vertical resize +4'))
vim.keymap.set('n', '<Right>', vcmd('vertical resize -4'))
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
vim.keymap.set('n', 'U', vcmd('e!'))
-- edit init.vim file
vim.keymap.set('n', 'ze', vcmd('e ~/.config/nvim/init.lua'))
-- have Y mimic D and C etc
vim.keymap.set('n', 'Y', 'y$')
-- I use this specific directory a lot
vim.keymap.set('n', 'g;', ':e ~/tests/')
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
vim.keymap.set('n', '<leader>g', 'diw"0P')
vim.keymap.set('n', '<leader>G', 'diW"0P')
-- get quick access to all unbinded keys
vim.keymap.set('n', '<leader>n', ':norm! ')
-- move to true end/begin of file.
vim.keymap.set('n', 'G', 'G$')
vim.keymap.set('n', 'gg', 'gg^')
-- quickfix list navigation
vim.keymap.set('n', 'gm', vcmd('cnext'))
vim.keymap.set('n', 'g,', vcmd('cprev'))
