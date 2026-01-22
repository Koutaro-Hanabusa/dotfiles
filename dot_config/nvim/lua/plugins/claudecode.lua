return {
  "coder/claudecode.nvim",
  config = function()
    require("claudecode").setup({
      terminal = {
        split_side = "right",
        split_width_percentage = 0.40,
        provider = "native", -- snacks.nvimが不要
      },
      diff_opts = {
        auto_close_on_accept = true,
      },
      git_repo_cwd = true,
    })
  end,
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>aa", ":ClaudeCodeAdd %<cr>", desc = "Add current file to Claude" },
  },
}
