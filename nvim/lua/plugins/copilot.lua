-- GitHub Copilot completion (参考: https://zenn.dev/masafumi330/articles/d85dbda96ff535)
-- Provides inline AI suggestions with Tab accept similar to VS Code.

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "BufReadPost",
    config = function()
      require("copilot").setup({
        suggestion = {
          auto_trigger = true,
          keymap = {
            accept = "<Tab>",
            accept_word = "<C-j>",
            accept_line = "<C-k>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        panel = { enabled = false },
      })
    end,
  },
}
