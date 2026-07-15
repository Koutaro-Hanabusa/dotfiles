-- DBML ftplugin: render サブコマンドで SVG を生成し image.nvim でインライン表示
--
-- 前提:
--   - dbml-language-server が PATH に存在 (home.nix で dbmlLspPkg を追加済み)
--   - image.nvim がロード済み (Ghostty + magick_cli で SVG→PNG 変換される)

vim.bo.commentstring = "// %s"

-- 現在バッファの状態管理: 直近の preview 画像オブジェクトを持っておいて再描画時に破棄する
local last_image = nil

local function notify_err(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

local function ensure_image_lib()
  local ok, image = pcall(require, "image")
  if not ok then
    notify_err("image.nvim が読み込めない (dbml preview)")
    return nil
  end
  return image
end

local function preview_current()
  local input = vim.fn.expand("%:p")
  if input == "" then
    notify_err("バッファが未保存")
    return
  end

  -- render 実行 (SVG を tempfile へ)
  local output = vim.fn.tempname() .. ".svg"
  local result = vim.system({ "dbml-language-server", "render", input, "-o", output }, { text = true }):wait()
  if result.code ~= 0 then
    notify_err("dbml render 失敗: " .. (result.stderr or "unknown"))
    return
  end

  local image = ensure_image_lib()
  if not image then return end

  -- 既存プレビュー画像を先に消す (再描画対応)
  if last_image then
    pcall(function() last_image:clear() end)
    last_image = nil
  end

  -- プレビュー用の縦分割を用意 (既に開いていれば再利用)
  local preview_bufname = "dbml-preview://" .. input
  local existing_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf) == preview_bufname then
      existing_win = win
      break
    end
  end

  local win, buf
  if existing_win then
    win = existing_win
    buf = vim.api.nvim_win_get_buf(win)
    vim.api.nvim_set_current_win(win)
  else
    vim.cmd("vsplit")
    win = vim.api.nvim_get_current_win()
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_buf_set_name(buf, preview_bufname)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "dbml-preview"
    -- プレビューウィンドウを閉じたら元のウィンドウに戻す用の keymap
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
  end

  local img = image.from_file(output, {
    window = win,
    buffer = buf,
    with_virtual_padding = true,
  })
  if not img then
    notify_err("image.nvim: from_file が nil を返した")
    return
  end
  img:render()
  last_image = img
end

vim.keymap.set("n", "<leader>dv", preview_current, {
  buffer = true,
  desc = "DBML: preview ER diagram (SVG in split)",
})

-- 保存時にプレビュー開いてたら自動で再描画
vim.api.nvim_create_autocmd("BufWritePost", {
  buffer = 0,
  callback = function()
    if last_image then
      preview_current()
    end
  end,
})
