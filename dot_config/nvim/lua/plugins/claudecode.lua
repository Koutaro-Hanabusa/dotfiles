return {
  "coder/claudecode.nvim",
  event = "VeryLazy",
  config = function()
    require("claudecode").setup({
      auto_start = true, -- プラグイン側で自動起動を制御
      terminal = {
        split_side = "right",
        split_width_percentage = 0.40,
        provider = "native",
      },
      diff_opts = {
        auto_close_on_accept = true,
      },
      git_repo_cwd = true,
    })

    -- ClaudeCodeターミナルにフォーカス時にinsertモードに切り替え
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "term://*claude*",
      callback = function()
        vim.cmd("startinsert")
      end,
    })
  end,
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>aa", ":ClaudeCodeAdd %<cr>", desc = "Add current file to Claude" },
  },
}
