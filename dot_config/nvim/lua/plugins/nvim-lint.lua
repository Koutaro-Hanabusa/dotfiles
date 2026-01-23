return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      markdown = { "textlint" },
      text = { "textlint" },
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

    -- リポジトリ全体のmdファイルをチェック (quickfixに出力)
    vim.keymap.set("n", "<leader>la", function()
      vim.cmd('cexpr system("textlint --format unix \"**/*.md\" 2>/dev/null")')
      vim.cmd("copen")
    end, { desc = "Textlint all md files" })
  end,
}
