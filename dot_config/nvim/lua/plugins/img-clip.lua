return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    default = {
      -- 画像の保存先（現在のファイルからの相対パス）
      dir_path = "assets/images",
      -- ファイル名の形式
      file_name = "%Y-%m-%d-%H-%M-%S",
      -- markdownでの埋め込み形式
      use_absolute_path = false,
      relative_to_current_file = true,
      prompt_for_file_name = true,
      drag_and_drop = {
        insert_mode = true,
      },
    },
    filetypes = {
      markdown = { enabled = true },
      vimwiki = { enabled = true },
      html = { enabled = true },
      asciidoc = { enabled = true },
      tex = { enabled = true },
      typst = { enabled = true },
      rst = { enabled = true },
      org = { enabled = true },
    },
  },
  keys = {
    { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
  },
}
