return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true, -- treesitterを使って賢くペアリング
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
        typescript = { "template_string" },
      },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {
      opts = {
        enable_close = true, -- 自動閉じタグ
        enable_rename = true, -- タグ名変更時に対応タグも変更
        enable_close_on_slash = true, -- </を入力したら自動で閉じる
      },
    },
  },
}
