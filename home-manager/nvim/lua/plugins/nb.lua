-- nb.nvim: nb CLI ノート (home:/work:) を Neovim から検索・編集・自動同期する。
-- <leader>nb で全ノート横断ピッカーを開き、プレビューを見ながら選択。q でピッカーを閉じる。
return {
  "mozumasu/nb.nvim",
  dependencies = { "folke/snacks.nvim" },
  lazy = false, -- 保存時の autosync autocmd を起動時に登録
  opts = {
    autosync = true,
  },
  keys = {
    { "<leader>nb", function() require("nb").pick() end, desc = "nb picker (all notes)" },
    { "<leader>ng", function() require("nb").grep() end, desc = "nb grep (contents)" },
    { "<leader>na", function() require("nb").add() end, desc = "nb add (current notebook)" },
    { "<leader>nA", function() require("nb").add_select() end, desc = "nb add (select notebook)" },
    { "<leader>nl", function() require("nb").link() end, desc = "nb insert link" },
    { "<leader>nm", function() require("nb").move() end, desc = "nb move to notebook" },
    { "<leader>nM", function() require("nb").adopt_buffer() end, desc = "nb adopt current buffer" },
    { "<leader>ni", function() require("nb").import_image() end, desc = "nb import image" },
  },
}
