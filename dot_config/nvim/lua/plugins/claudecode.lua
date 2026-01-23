return {
  "coder/claudecode.nvim",
  lazy = false, -- Claude Codeとの接続を即座に確立
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
  },
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

    -- ターミナルモードで Ctrl+v でクリップボードからペースト
    vim.keymap.set("t", "<C-v>", '<C-\\><C-n>"+pi', { desc = "Paste in terminal" })
  end,
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>aa", ":ClaudeCodeAdd %<cr>", desc = "Add current file to Claude" },
  },
}
