return {
  {
    "aaronik/treewalker.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
    keys = {
      { "gh", "<cmd>Treewalker Left<cr>", desc = "Treewalker Move Left" },
      { "gj", "<cmd>Treewalker Down<cr>", desc = "Treewalker Move Down" },
      { "gk", "<cmd>Treewalker Up<cr>", desc = "Treewalker Move Up" },
      { "gl", "<cmd>Treewalker Right<cr>", desc = "Treewalker Move Right" },
    },
  },
}
