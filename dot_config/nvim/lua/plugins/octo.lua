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
  end,
}
