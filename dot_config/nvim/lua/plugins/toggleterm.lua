return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = 10, -- Smaller terminal height
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true, -- insertモードで開始
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = false, -- insertモードを記憶しない
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

    -- gh-dash用のカスタムターミナル
    local Terminal = require("toggleterm.terminal").Terminal
    local ghdash = Terminal:new({
      cmd = "gh dash",
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "curved",
      },
      on_open = function(term)
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
      end,
      on_close = function(_)
      end,
    })

    local function ghdash_toggle()
      ghdash:toggle()
    end

    keymap("n", "<leader>gh", ghdash_toggle, { desc = "Open gh-dash" })
  end,
}
