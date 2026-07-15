return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  -- 必要な parser をここに列挙。初回起動時に自動 install される。
  -- 追加は :TSInstall <lang> または本テーブルに追記して restart。
  config = function()
    local parsers_to_install = { "markdown", "markdown_inline" }
    local ok, ts = pcall(require, "nvim-treesitter")
    if not ok then return end
    -- install() は idempotent (既存はスキップ)。非同期で走るので初回起動時は
    -- 少し待つ必要があるが、以降は永続化される。
    pcall(function() ts.install(parsers_to_install) end)
  end,
}
