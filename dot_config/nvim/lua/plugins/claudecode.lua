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

    -- NOTE: BufEnter + startinsert は削除済み
    -- nativeプロバイダーが内部でstartinsertを管理しているため、
    -- 重複するとClaude Code TUIのスクロール位置がリセットされる

    -- ターミナルモードで Ctrl+v でクリップボードからペースト
    -- 注: Cmd+V（macOS標準）の方が確実。これはfallback用
    vim.keymap.set("t", "<C-v>", function()
      local clipboard = vim.fn.getreg("+")
      if clipboard == "" then return end
      -- ブラケットペーストモードで送信
      local bracketed = "\x1b[200~" .. clipboard .. "\x1b[201~"
      local job_id = vim.b.terminal_job_id
      if job_id then
        vim.fn.chansend(job_id, bracketed)
      end
    end, { desc = "Paste in terminal" })
  end,
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session (picker)" },
    { "<leader>ao", "<cmd>ClaudeCode --continue<cr>", desc = "Continue last session" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>aa", ":ClaudeCodeAdd %<cr>", desc = "Add current file to Claude" },
  },
}
