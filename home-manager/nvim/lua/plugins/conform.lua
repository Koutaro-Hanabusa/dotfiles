return {
  "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        html = { "prettier" },
        markdown = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        graphql = { "prettier" },
        lua = { "stylua" },
        python = { "black" },
        go = { "gofmt" },
        php = { "pint" },
      },
      formatters = {
        -- プロジェクトの node_modules/.bin/<tool> を優先（無ければ PATH へフォールバック）
        prettier = { prefer_local = "node_modules/.bin" },
        eslint_d = { prefer_local = "node_modules/.bin" },
        biome    = { prefer_local = "node_modules/.bin" },
        stylelint = { prefer_local = "node_modules/.bin" },
        -- Laravel: vendor/bin/pint を優先
        pint = { prefer_local = "vendor/bin" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    })

    -- 手動フォーマット用キーマップ
    vim.keymap.set("n", "<leader>f", function()
      require("conform").format({ async = true, lsp_fallback = true })
    end, { desc = "Format buffer" })
  end,
}
