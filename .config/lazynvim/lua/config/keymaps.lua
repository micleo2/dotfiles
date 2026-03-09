-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "Q", "<cmd>q!<cr>", { desc = "Force Quit" })
map("n", "<leader>q", "<cmd>wqa<cr>", { desc = "Save All and Quit" })

-- save files quickly
map("n", "<leader>w", "<cmd>up<cr>", { desc = "Save File" })
map("n", "<leader>W", "<cmd>wa<cr>", { desc = "Save All Files" })

-- esc in normal mode to turn off search highlight
-- use cmd so that the cmdline prompt doesn't show briefly
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear Search Highlight" })

-- No ARRRROWWS!!!!
map("n", "<Up>", "<cmd>resize +4<cr>", { desc = "Increase Window Height" })
map("n", "<Down>", "<cmd>resize -4<cr>", { desc = "Decrease Window Height" })
map("n", "<Left>", "<cmd>vertical resize +4<cr>", { desc = "Increase Window Width" })
map("n", "<Right>", "<cmd>vertical resize -4<cr>", { desc = "Decrease Window Width" })

-- Better window keybinds
map("n", "<leader>h", "<C-w>h", { desc = "Go to Left Window" })
map("n", "<leader>j", "<C-w>j", { desc = "Go to Lower Window" })
map("n", "<leader>J", "<C-w>s<C-w>j", { desc = "Split and Go Down" })
map("n", "<leader>k", "<C-w>k", { desc = "Go to Upper Window" })
map("n", "<leader>l", "<C-w>l", { desc = "Go to Right Window" })
map("n", "<leader>L", "<C-w>v<C-w>l", { desc = "Split and Go Right" })

-- search in visual mode
map("v", "//", 'y/<C-R>"<CR>', { desc = "Search Selection" })

-- set b/l to go to begin or end of line
map("n", "<C-h>", "^", { desc = "Go to Line Start" })
map("n", "<C-l>", "$", { desc = "Go to Line End" })
map("v", "<C-h>", "^", { desc = "Go to Line Start" })
map("v", "<C-l>", "$", { desc = "Go to Line End" })

-- ctrl b gets caught by tmux, so use ctrl-k/f instead
map("n", "<C-k>", "<C-b>", { desc = "Page Up" })
map("v", "<C-k>", "<C-b>", { desc = "Page Up" })

-- U reverts file to last save
map("n", "U", "<cmd>e!<cr>", { desc = "Revert File" })

-- edit init.vim file
map("n", "ze", "<cmd>e ~/.config/nvim/init.lua<cr>", { desc = "Edit Config" })

-- have Y mimic D and C etc
map("n", "Y", "y$", { desc = "Yank to End of Line" })

-- I use this specific directory a lot
map("n", "g;", ":e ~/tests/", { desc = "Open Tests Dir" })

-- make new lines while staying where you are
map("n", "<leader>i", "mlo<ESC>`l", { desc = "Insert Line Below" })
map("n", "<leader>I", "mlO<ESC>`l", { desc = "Insert Line Above" })

-- surround current line with newlines above and below
map("n", "<leader>s", "mlO<ESC>jo<ESC>`l", { desc = "Surround Line with Blanks" })

-- -- Re-order lines
-- map('n', 'J', ':let c=col(\".\")<CR>:execute \"normal! ddp\" . c . \"\|\"<CR>')
-- map('n', 'K', ':let c=col(\".\")<CR>:execute \"normal! ddkP\" . c . \"\|\"<CR>')

-- replace current word and leave dot more useful
map("n", "<leader>cr", "ml*`lcgn", { desc = "Replace Current Word" })
map("n", "<leader>cg", 'diw"0P', { desc = "Paste Over Word" })
map("n", "<leader>cG", 'diW"0P', { desc = "Paste Over WORD" })

-- get quick access to all unbinded keys
map("n", "<leader>n", ":norm! ", { desc = "Normal Command" })

-- move to true end/begin of file
map("n", "G", "G$", { desc = "Go to End of File" })
map("n", "gg", "gg^", { desc = "Go to Start of File" })
