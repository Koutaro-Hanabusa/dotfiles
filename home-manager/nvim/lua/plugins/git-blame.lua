return {
  "f-person/git-blame.nvim",
  config = function()
    require("gitblame").setup({
      enabled = true,
    })

    vim.keymap.set("n", "<leader>gb", ":GitBlameToggle<CR>", { desc = "Toggle Git Blame" })
  end,
}