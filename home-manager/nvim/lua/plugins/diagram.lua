-- markdown 内の ```mermaid ブロックを SVG レンダしてインライン表示する。
-- image.nvim + mermaid-cli (mmdc) が前提。両方すでに揃っている想定。
return {
  "3rd/diagram.nvim",
  dependencies = { "3rd/image.nvim" },
  ft = { "markdown", "vimwiki" },
  -- opts をテーブルリテラルで書くと require が遅延ロード前に走って落ちるので関数化
  opts = function()
    return {
      renderer_options = {
        mermaid = {
          background_color = "transparent",
          theme = "default",
        },
      },
      integrations = {
        require("diagram.integrations.markdown"),
      },
    }
  end,
}
