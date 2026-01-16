return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    toggler = {
      line = "<leader>cc",  -- 行コメントトグル
      block = "<leader>cb", -- ブロックコメントトグル
    },
    opleader = {
      line = "<leader>c",   -- 行コメント（モーション用）
      block = "<leader>b",  -- ブロックコメント（モーション用）
    },
  },
}
