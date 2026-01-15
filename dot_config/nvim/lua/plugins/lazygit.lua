return {
  "kdheepak/lazygit.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    -- LazyGitが開いた時にターミナルモードで始まる
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*lazygit*",
      callback = function()
        vim.cmd("startinsert")
      end,
    })

    -- キーマッピング
    vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "Open LazyGit" })
    vim.keymap.set("n", "<leader>gf", "<cmd>LazyGitFilter<cr>", { desc = "LazyGit current file history" })
    vim.keymap.set("n", "<leader>gc", "<cmd>LazyGitFilterCurrentFile<cr>", { desc = "LazyGit commits for current file" })
  end,
}
