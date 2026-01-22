-- MDXをmarkdownとして扱う
vim.filetype.add({
  extension = {
    mdx = "markdown",
  },
})

-- Basic settings
vim.opt.number = true
vim.opt.autoread = true
vim.opt.clipboard = "unnamedplus"  -- yank時にシステムクリップボードにもコピー
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
vim.opt.fixendofline = true  -- ファイル末尾に改行を保証

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Key mappings for mode switching
vim.keymap.set("i", "jj", "<ESC>")

-- InsertモードからNormalモードに戻る時に英数入力に切り替え（macOS）
if vim.fn.has("mac") == 1 then
  local im_select_cmd = "im-select"
  local default_im = "com.apple.keylayout.ABC" -- 英数

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      vim.fn.jobstart({ im_select_cmd, default_im }, { detach = true })
    end,
  })
end

-- File path copy keymaps
vim.keymap.set("n", "<leader>yp", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
  print("Copied relative path: " .. vim.fn.expand("%"))
end, { desc = "Copy relative file path" })

vim.keymap.set("n", "<leader>yP", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  print("Copied absolute path: " .. vim.fn.expand("%:p"))
end, { desc = "Copy absolute file path" })

vim.keymap.set("n", "<leader>yn", function()
  vim.fn.setreg("+", vim.fn.expand("%:t"))
  print("Copied filename: " .. vim.fn.expand("%:t"))
end, { desc = "Copy filename" })

vim.keymap.set("n", "<leader>yd", function()
  vim.fn.setreg("+", vim.fn.expand("%:p:h"))
  print("Copied directory path: " .. vim.fn.expand("%:p:h"))
end, { desc = "Copy directory path" })

-- Window split keymaps
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- New buffer keymaps
vim.keymap.set("n", "<leader>bn", "<cmd>enew<CR>", { desc = "New empty buffer" })
vim.keymap.set("n", "<leader>bv", "<cmd>vnew<CR>", { desc = "New buffer in vertical split" })
vim.keymap.set("n", "<leader>bh", "<cmd>new<CR>", { desc = "New buffer in horizontal split" })

-- Window navigation keymaps
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })

-- Window resize keymaps
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Tmux pane zoom toggle
vim.keymap.set("n", "<leader>z", function()
  vim.fn.system("tmux resize-pane -Z")
end, { desc = "Toggle tmux pane zoom" })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup("plugins", {
  change_detection = {
    notify = false,
  },
})

-- 外部でファイルが変更されたら自動で再読み込み
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

-- ファイル変更時に通知
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.WARN)
  end,
})

-- ターミナルが開いたらinsertモードにする
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.cmd([[startinsert]])
  end,
})

-- Auto-open layout on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Only auto-open if no file was specified
    if vim.fn.argc() == 0 then
      -- Open nvim-tree
      vim.cmd("NvimTreeOpen")

      -- Wait a bit for nvim-tree to open, then open terminal
      vim.defer_fn(function()
        -- Move to the main window (not nvim-tree)
        vim.cmd("wincmd l")
        -- Remember the editor window
        local editor_win = vim.api.nvim_get_current_win()
        -- Open terminal at the bottom with smaller height
        vim.cmd("ToggleTerm size=10 direction=horizontal")
        -- Wait for terminal to fully open, then move back
        vim.defer_fn(function()
          -- Focus editor window
          vim.api.nvim_set_current_win(editor_win)
        end, 200)
      end, 100)
    end
  end,
})

-- :q で全てのウィンドウを閉じて終了
vim.api.nvim_create_user_command("Q", "qa", {})
vim.keymap.set("c", "q<CR>", function()
  -- 現在のバッファが通常のファイルバッファかチェック
  local buftype = vim.bo.buftype
  local filetype = vim.bo.filetype

  -- NvimTreeやToggleTermなど特殊バッファの場合は全終了
  if filetype == "NvimTree" or buftype == "terminal" then
    vim.cmd("qa")
  else
    -- 通常バッファの数をカウント
    local normal_bufs = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local bt = vim.api.nvim_get_option_value("buftype", { buf = buf })
        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
        if bt == "" and ft ~= "NvimTree" then
          normal_bufs = normal_bufs + 1
        end
      end
    end

    -- 通常バッファが1つ以下なら全終了、それ以上なら通常の:q
    if normal_bufs <= 1 then
      vim.cmd("qa")
    else
      vim.cmd("q")
    end
  end
end, { noremap = true })