return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        telescope = true,
        nvimtree = true,
        gitsigns = true,
        indent_blankline = {
          enabled = true,
        },
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}