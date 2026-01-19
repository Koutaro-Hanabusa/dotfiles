return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>dv", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
    { "<leader>dc", "<cmd>DiffviewClose<CR>", desc = "Close Diffview" },
    { "<leader>dh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
    { "<leader>dH", "<cmd>DiffviewFileHistory<CR>", desc = "File history (all)" },
  },
  config = function()
    require("diffview").setup({
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
          disable_diagnostics = true,
        },
      },
      keymaps = {
        view = {
          ["<leader>co"] = "<cmd>DiffviewConflictPick ours<CR>",
          ["<leader>ct"] = "<cmd>DiffviewConflictPick theirs<CR>",
          ["<leader>cb"] = "<cmd>DiffviewConflictPick base<CR>",
          ["<leader>ca"] = "<cmd>DiffviewConflictPick all<CR>",
        },
      },
    })
  end,
}
