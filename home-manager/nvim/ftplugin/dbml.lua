-- DBML ftplugin: render サブコマンドで SVG を生成し image.nvim でインライン表示
--
-- 前提:
--   - dbml-language-server が PATH に存在 (home.nix で dbmlLspPkg を追加済み)
--   - image.nvim がロード済み (Ghostty + magick_cli で SVG→PNG 変換される)

vim.bo.commentstring = "// %s"

-- プレビュー状態:
--   preview_active — ユーザーが「プレビューを見たい」意思表示中か。
--                    :Er で true、プレビューウィンドウを閉じたら false。
--                    保存時の自動再描画はこのフラグだけを見る (last_image は見ない)。
--   last_image     — image.nvim のハンドル。差し替え / 破棄用。
local preview_active = false
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

local function clear_current_image()
  if last_image then
    pcall(function() last_image:clear() end)
    last_image = nil
  end
end

local function preview_current()
  local input = vim.fn.expand("%:p")
  if input == "" then
    notify_err("バッファが未保存")
    return
  end

  local output = vim.fn.tempname() .. ".svg"
  local result = vim.system({ "dbml-language-server", "render", input, "-o", output }, { text = true }):wait()
  if result.code ~= 0 then
    -- 古い ER 図が残ると「今の DBML の絵」だと誤解されるので即消す。
    -- preview_active は維持 → syntax を直して次に保存したら自動再描画される。
    clear_current_image()
    notify_err("dbml render 失敗: " .. (result.stderr or "unknown"))
    return
  end

  local image = ensure_image_lib()
  if not image then return end

  clear_current_image()

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
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })

    -- プレビューを閉じたら「もう表示したくない」と解釈し、
    -- 保存時の自動再描画を止める。bufhidden=wipe なので :close で確実に発火する。
    vim.api.nvim_create_autocmd("BufWipeout", {
      buffer = buf,
      once = true,
      callback = function()
        preview_active = false
        clear_current_image()
      end,
    })
  end

  preview_active = true

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

-- コマンドで叩く前提 (keymap は他プラグインとの衝突を避けるため未登録)。
--   :Er                 — プレビューを開く / 再描画 (dbml view)
--   プレビュー側で `q`  — プレビューを閉じる (以後の自動再描画も停止)
-- ※ buffer-local なので .dbml バッファ以外では `:Er` は存在しない。
vim.api.nvim_buf_create_user_command(0, "Er", preview_current, {
  desc = "DBML: preview ER diagram (SVG in split)",
})

-- 保存時、プレビューが「見たい」状態のときだけ再描画。
-- 閉じた後 (preview_active=false) は勝手に開かない。
vim.api.nvim_create_autocmd("BufWritePost", {
  buffer = 0,
  callback = function()
    if preview_active then
      preview_current()
    end
  end,
})
