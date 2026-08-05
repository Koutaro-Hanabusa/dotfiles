return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local bufferline = require("bufferline")

    bufferline.setup({
      options = {
        -- タブの塗り分けをやめて下線だけで現在位置を示す
        style_preset = bufferline.style_preset.minimal,
        indicator = { style = "underline" },
        separator_style = "thin",
        -- diagnostics は lualine 側に出しているのでタブには重ねない
        diagnostics = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        offsets = {
          {
            filetype = "NvimTree",
            text = "",
            separator = true,
          },
        },
      },
    })

    vim.keymap.set("n", "<S-l>", ":BufferLineCycleNext<CR>", { desc = "Next buffer" })
    vim.keymap.set("n", "<S-h>", ":BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
    vim.keymap.set("n", "<leader>bx", ":BufferLinePickClose<CR>", { desc = "Close buffer (pick)" })
  end,
}