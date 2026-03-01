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

    -- Claudeターミナルに戻ったときにinsertモードに切り替え
    -- WinEnter + 条件チェックで不要な発火を抑制（スクロールリセット防止）
    vim.api.nvim_create_autocmd("WinEnter", {
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].buftype == "terminal" then
          local name = vim.api.nvim_buf_get_name(buf)
          if name:match("claude") and vim.fn.mode() ~= "t" then
            vim.cmd("startinsert")
          end
        end
      end,
    })

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
    {
      "<leader>ac",
      function()
        vim.fn.system("tmux split-window -h -l 40%")
      end,
      desc = "Open tmux terminal (right)",
    },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session (picker)" },
    { "<leader>ao", "<cmd>ClaudeCode --continue<cr>", desc = "Continue last session" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>aa", ":ClaudeCodeAdd %<cr>", desc = "Add current file to Claude" },
  },
}
