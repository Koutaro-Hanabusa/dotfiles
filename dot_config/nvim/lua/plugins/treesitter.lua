return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  -- nvim-treesitter 1.0+ ではsetup()は不要
  -- パーサーのインストール: :TSInstall <lang>
  -- ハイライトはNeovim 0.10+でパーサーがあれば自動有効
}
