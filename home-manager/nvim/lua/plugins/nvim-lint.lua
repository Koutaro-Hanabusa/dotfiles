return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- プロジェクト同梱の node_modules/.bin/<name> を優先
    local function find_local_bin(name)
      local file = vim.api.nvim_buf_get_name(0)
      local start = file ~= "" and vim.fs.dirname(file) or (vim.uv or vim.loop).cwd()
      local root = vim.fs.root(start, "node_modules")
      if root then
        local candidate = root .. "/node_modules/.bin/" .. name
        if vim.fn.executable(candidate) == 1 then
          return candidate
        end
      end
      return name
    end

    -- textlintのカスタムリンター定義
    lint.linters.textlint = {
      cmd = function() return find_local_bin("textlint") end,
      stdin = false,
      args = { "--format", "json", "--no-color", "--ignore-path", vim.fn.expand("~/.textlintignore") },
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
      local bin = find_local_bin("textlint")
      vim.cmd("!" .. vim.fn.shellescape(bin) .. " --fix --ignore-path ~/.textlintignore " .. vim.fn.shellescape(file))
      vim.cmd("edit!")
    end, { desc = "Textlint fix current file" })

    -- リポジトリ全体のmd,ts,tsx,js,jsxファイルをチェック (quickfixに出力)
    vim.keymap.set("n", "<leader>la", function()
      local bin = find_local_bin("textlint")
      local result = vim.fn.system(vim.fn.shellescape(bin) .. ' --format unix --ignore-path ~/.textlintignore "**/*.md" "**/*.ts" "**/*.tsx" "**/*.js" "**/*.jsx" 2>/dev/null')
      vim.fn.setqflist({}, "r", { lines = vim.split(result, "\n"), title = "Textlint" })
      vim.cmd("copen")
    end, { desc = "Textlint all files" })
  end,
}
