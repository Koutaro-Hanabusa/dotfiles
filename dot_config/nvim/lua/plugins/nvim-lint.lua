return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- textlintのカスタムリンター定義
    lint.linters.textlint = {
      cmd = "textlint",
      stdin = false,
      args = { "--format", "json", "--no-color" },
      ignore_exitcode = true,
      parser = function(output, bufnr)
        local diagnostics = {}
        if output == "" then
          return diagnostics
        end
        local ok, results = pcall(vim.json.decode, output)
        if not ok or not results or #results == 0 then
          return diagnostics
        end
        for _, file_result in ipairs(results) do
          for _, msg in ipairs(file_result.messages or {}) do
            table.insert(diagnostics, {
              lnum = (msg.line or 1) - 1,
              col = (msg.column or 1) - 1,
              end_lnum = (msg.line or 1) - 1,
              end_col = (msg.column or 1) - 1,
              severity = msg.severity == 2 and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
              message = msg.message,
              source = "textlint",
            })
          end
        end
        return diagnostics
      end,
    }

    lint.linters_by_ft = {
      markdown = { "textlint" },
      text = { "textlint" },
      javascript = { "textlint" },
      typescript = { "textlint" },
      javascriptreact = { "textlint" },
      typescriptreact = { "textlint" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    -- 現在のファイルをlint
    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
    end, { desc = "Lint current file" })

    -- 現在のファイルをtextlintで自動修正
    vim.keymap.set("n", "<leader>lf", function()
      local file = vim.fn.expand("%:p")
      vim.cmd("!textlint --fix " .. vim.fn.shellescape(file))
      vim.cmd("edit!")
    end, { desc = "Textlint fix current file" })

    -- リポジトリ全体のmd,ts,tsx,js,jsxファイルをチェック (quickfixに出力)
    vim.keymap.set("n", "<leader>la", function()
      local result = vim.fn.system('textlint --format unix "**/*.md" "**/*.ts" "**/*.tsx" "**/*.js" "**/*.jsx" 2>/dev/null')
      vim.fn.setqflist({}, "r", { lines = vim.split(result, "\n"), title = "Textlint" })
      vim.cmd("copen")
    end, { desc = "Textlint all files" })
  end,
}
