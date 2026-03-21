return {
  "mikavilpas/yazi.nvim",
  enabled = false,
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    {
      "<leader>y",
      "<cmd>Yazi<cr>",
      desc = "Open yazi at current file",
    },
    {
      "<leader>Y",
      "<cmd>Yazi cwd<cr>",
      desc = "Open yazi in working directory",
    },
  },
  opts = {
    open_for_directories = true,
    floating_window_scaling_factor = 0.9,
    yazi_floating_window_border = "rounded",
    keymaps = {
      show_help = "<f1>",
    },
    yazi_floating_window_env = {
      PATH = os.getenv("PATH") or "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
    },
  },
}
