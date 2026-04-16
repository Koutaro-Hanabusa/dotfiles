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
    local actions = require("diffview.actions")
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
          { "n", "<leader>co", actions.conflict_choose("ours"), { desc = "Choose OURS (left)" } },
          { "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "Choose THEIRS (right)" } },
          { "n", "<leader>cb", actions.conflict_choose("base"), { desc = "Choose BASE" } },
          { "n", "<leader>ca", actions.conflict_choose("all"), { desc = "Choose ALL" } },
          { "n", "[x", actions.prev_conflict, { desc = "Prev conflict" } },
          { "n", "]x", actions.next_conflict, { desc = "Next conflict" } },
        },
      },
    })
  end,
}
