return {
  {
    "folke/snacks.nvim",
    opts = {
      statuscolumn = { left = { "sign" } },
    },
    keys = {
      {
        "<C-p>",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<C-s>",
        function()
          Snacks.picker.smart()
        end,
        desc = "Smart Find Files",
      },
      {
        "<C-c>",
        function()
          Snacks.picker.files({ cwd = vim.fn.expand("$HOME/.config") })
        end,
        desc = "Search ~/.config",
      },
      {
        "<C-x>",
        function()
          Snacks.explorer()
        end,
        desc = "File Explorer",
      },
      {
        "<C-n>",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      -- Restore default H/L behavior
      { "<leader>e", false },
      { "<leader>E", false },
    },
  },
}
