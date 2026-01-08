return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require("nvim-tree").setup({
      sync_root_with_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      view = {
        width = 35, -- File tree width
        side = "left",
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
      actions = {
        open_file = {
          quit_on_open = false, -- Don't close tree when opening a file
        },
      },
    })

    vim.keymap.set("n", "<leader>e", ":NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer" })
  end,
}