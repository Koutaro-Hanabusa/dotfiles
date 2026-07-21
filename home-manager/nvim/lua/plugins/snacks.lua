-- nb.nvim の picker UI 依存として導入。他機能は既存プラグイン（lualine/bufferline 等）と
-- 競合するため picker と関連モジュールのみ有効化する。
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      enabled = true,
      layout = {
        preset = "default", -- 右側にプレビュー
      },
      win = {
        input = {
          keys = {
            ["q"] = { "close", mode = { "n" } },
          },
        },
      },
    },
    input = { enabled = true },
    notifier = { enabled = false },
    quickfile = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
  },
}
