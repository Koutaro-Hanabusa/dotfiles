-- マークダウンでリストを自動継続
-- 改行時に - や * や 1. などを自動挿入

-- formatoptions の設定
-- r: Enterキーで改行時にコメント文字を自動挿入
-- o: o/Oで新行作成時にコメント文字を自動挿入
vim.opt_local.formatoptions:append("r")
vim.opt_local.formatoptions:append("o")

-- マークダウンのリスト記号をコメントとして認識させる
vim.opt_local.comments = "b:-,b:*,b:+,b:1."

-- :md でcmuxマークダウンビューアをトグル（ライブリロード付き）
local cmux_viewer_surface = nil

local function close_cmux_viewer()
  if cmux_viewer_surface then
    vim.fn.system("cmux close-surface --surface " .. cmux_viewer_surface)
    cmux_viewer_surface = nil
  end
end

vim.api.nvim_buf_create_user_command(0, "md", function()
  if vim.env.CMUX_SOCKET_PATH == nil or vim.fn.executable("cmux") == 0 then
    vim.notify("cmux が利用できません。glow で表示します", vim.log.levels.INFO)
    vim.fn.system("glow -p " .. vim.fn.shellescape(vim.fn.expand("%:p")))
    return
  end

  -- トグル: 既に開いていたら閉じる
  if cmux_viewer_surface then
    close_cmux_viewer()
    return
  end

  local result = vim.fn.system("cmux markdown open " .. vim.fn.shellescape(vim.fn.expand("%:p")))
  local surface = result:match("surface:(%d+)")
  if surface then
    cmux_viewer_surface = "surface:" .. surface
  end
end, { desc = "Toggle cmux markdown viewer" })

-- バッファを離れたらビューアを閉じる
vim.api.nvim_create_autocmd("BufLeave", {
  buffer = 0,
  callback = close_cmux_viewer,
})
