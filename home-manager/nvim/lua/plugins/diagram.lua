-- markdown 内の ```mermaid ブロックを SVG レンダしてインライン表示する。
-- image.nvim + mermaid-cli (mmdc) が前提。両方すでに揃っている想定。
return {
  "3rd/diagram.nvim",
  dependencies = { "3rd/image.nvim" },
  ft = { "markdown", "vimwiki" },
  -- opts をテーブルリテラルで書くと require が遅延ロード前に走って落ちるので関数化
  opts = function()
    -- nixpkgs の mmdc は Chromium 同梱していないので、既存シェル起動でも
    -- 確実に効くよう nvim プロセスの env にも Chrome パスを設定する。
    -- (home.sessionVariables の設定漏れフォールバック兼、二重保険)
    if vim.env.PUPPETEER_EXECUTABLE_PATH == nil or vim.env.PUPPETEER_EXECUTABLE_PATH == "" then
      vim.env.PUPPETEER_EXECUTABLE_PATH = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    end
    return {
      renderer_options = {
        mermaid = {
          -- diagram.nvim のオプション名は "background" (誤: background_color)
          background = "transparent",
          theme = "default",
        },
      },
      integrations = {
        require("diagram.integrations.markdown"),
      },
    }
  end,
}
