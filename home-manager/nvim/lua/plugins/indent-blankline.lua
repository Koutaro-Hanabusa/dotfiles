return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  config = function()
    require("ibl").setup({
      -- 細い罫線にして縦線の主張を弱める
      indent = {
        char = "▏",
      },
      -- カーソル位置のブロックを強調する scope は IDE 感が強いので切る
      scope = {
        enabled = false,
      },
    })
  end,
}