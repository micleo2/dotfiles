return {
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
      statuscolumn = { left = { "sign" } },
    },
    keys = {
      { "<C-p>", function() Snacks.picker.files() end, desc = "Find Files" },
      { "<C-s>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
      {
        "<C-c>",
        function()
          Snacks.picker.files({ cwd = vim.fn.expand("$HOME/.config") })
        end,
        desc = "Search ~/.config",
      },
      { "<C-x>", function() Snacks.explorer() end, desc = "File Explorer" },
      { "<C-n>", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "g:", function() Snacks.picker.command_history() end, desc = "Command History" },
      -- grep
      { "<leader>gg", function() Snacks.picker.grep() end, desc = "Grep" },
    },
  },
}
