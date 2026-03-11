return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("octo").setup({
      picker = "telescope",
      enable_builtin = true,
      default_remote = { "upstream", "origin" },
      default_merge_method = "squash",
      suppress_missing_scope = {
        projects_v2 = true,
      },
    })

    -- Keymaps for quick access
    vim.keymap.set("n", "<leader>ol", "<cmd>Octo pr list<CR>", { desc = "Octo: PR list" })
    vim.keymap.set("n", "<leader>oi", "<cmd>Octo issue list<CR>", { desc = "Octo: Issue list" })
    vim.keymap.set("n", "<leader>os", "<cmd>Octo search<CR>", { desc = "Octo: Search" })
    vim.keymap.set("n", "<leader>on", "<cmd>Octo notification list<CR>", { desc = "Octo: Notifications" })

    -- PR operations
    vim.keymap.set("n", "<leader>op", "<cmd>Octo pr checkout<CR>", { desc = "Octo: PR checkout" })
    vim.keymap.set("n", "<leader>od", "<cmd>Octo pr diff<CR>", { desc = "Octo: PR diff" })
    vim.keymap.set("n", "<leader>oc", "<cmd>Octo pr changes<CR>", { desc = "Octo: PR changes" })
    vim.keymap.set("n", "<leader>om", "<cmd>Octo pr merge<CR>", { desc = "Octo: PR merge" })
    vim.keymap.set("n", "<leader>ok", "<cmd>Octo pr checks<CR>", { desc = "Octo: PR checks" })

    -- Review workflow
    vim.keymap.set("n", "<leader>ors", "<cmd>Octo review start<CR>", { desc = "Octo: Start review" })
    vim.keymap.set("n", "<leader>oru", "<cmd>Octo review submit<CR>", { desc = "Octo: Submit review" })
    vim.keymap.set("n", "<leader>orr", "<cmd>Octo review resume<CR>", { desc = "Octo: Resume review" })
    vim.keymap.set("n", "<leader>orc", "<cmd>Octo review comments<CR>", { desc = "Octo: Review comments" })
    vim.keymap.set("n", "<leader>ord", "<cmd>Octo review discard<CR>", { desc = "Octo: Discard review" })

    -- Comments & threads
    vim.keymap.set("n", "<leader>oa", "<cmd>Octo comment add<CR>", { desc = "Octo: Add comment" })
    vim.keymap.set("n", "<leader>otr", "<cmd>Octo thread resolve<CR>", { desc = "Octo: Resolve thread" })
    vim.keymap.set("n", "<leader>otu", "<cmd>Octo thread unresolve<CR>", { desc = "Octo: Unresolve thread" })
  end,
}
