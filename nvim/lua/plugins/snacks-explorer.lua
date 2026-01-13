-- ~/.config/nvim/lua/plugins/snacks-explorer.lua
-- Purpose: Place Snacks explorer sidebar on the right by default.
-- Why: User requested right-side explorer in LazyVim.

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}

      local explorer = opts.picker.sources.explorer or {}
      explorer.layout = vim.tbl_deep_extend("force", explorer.layout or {}, {
        layout = { position = "right" },
      })
      opts.picker.sources.explorer = explorer
    end,
  },
}
