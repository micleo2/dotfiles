return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Remove the default trouble symbols component (last item in lualine_c)
      -- and replace it with one that filters out Namespace symbols
      if vim.g.trouble_lualine and LazyVim.has("trouble.nvim") then
        -- Remove the existing trouble component (appended last by LazyVim)
        table.remove(opts.sections.lualine_c)

        local trouble = require("trouble")
        local symbols = trouble.statusline({
          mode = "symbols",
          groups = {},
          title = false,
          filter = { range = true, ["not"] = { kind = "Namespace" } },
          format = "{kind_icon}{symbol.name:Normal}",
          hl_group = "lualine_c_normal",
        })
        table.insert(opts.sections.lualine_c, {
          symbols.get,
          cond = function()
            return vim.b.trouble_lualine ~= false and symbols.has()
          end,
        })
      end
    end,
  },
}
