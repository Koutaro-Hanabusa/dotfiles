return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show("<leader>")
      end,
      desc = "Show keymaps",
    },
  },
  opts = {
    delay = 300,
    icons = {
      separator = "→",
    },
    spec = {
      { "<leader>b", group = "Buffer" },
      { "<leader>f", group = "Find (Telescope)" },
      { "<leader>g", group = "Git" },
      { "<leader>h", group = "Hunk" },
      { "<leader>l", group = "LSP" },
      { "<leader>s", group = "Split" },
      { "<leader>t", group = "Terminal" },
      { "<leader>o", group = "Octo (GitHub)" },
      { "<leader>ot", group = "Thread" },
      { "<leader>r", group = "Review (Octo)" },
      { "<leader>x", group = "Diagnostics (Trouble)" },
      { "<leader>y", group = "Yank path" },
    },
  },
}
