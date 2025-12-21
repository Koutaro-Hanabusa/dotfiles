return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = 15, -- Smaller terminal height
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "horizontal", -- 'vertical' | 'horizontal' | 'tab' | 'float'
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      float_opts = {
        border = "curved",
        winblend = 0,
      },
    })

    -- キーマッピング
    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- <leader>t でターミナルをトグル
    keymap("n", "<leader>t", "<cmd>ToggleTerm<cr>", opts)
    keymap("t", "<leader>t", "<cmd>ToggleTerm<cr>", opts)

    -- ターミナルモードでESCでノーマルモードに戻る
    keymap("t", "<Esc>", [[<C-\><C-n>]], opts)
    keymap("t", "jj", [[<C-\><C-n>]], opts)

    -- 複数ターミナルの作成
    keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", opts)
    keymap("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", opts)
    keymap("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", opts)
  end,
}
