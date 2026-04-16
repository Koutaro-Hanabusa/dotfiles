return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose", "Review", "ReviewClose" },
  keys = {
    { "<leader>dv", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
    { "<leader>dc", "<cmd>DiffviewClose<CR>", desc = "Close Diffview" },
    { "<leader>dh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
    { "<leader>dH", "<cmd>DiffviewFileHistory<CR>", desc = "File history (all)" },
    { "<leader>rv", "<cmd>Review<CR>", desc = "Review: PR diff in editor" },
    { "<leader>rx", "<cmd>ReviewClose<CR>", desc = "Review: Close" },
  },
  config = function()
    local actions = require("diffview.actions")
    require("diffview").setup({
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
          disable_diagnostics = true,
        },
      },
      keymaps = {
        view = {
          { "n", "<leader>co", actions.conflict_choose("ours"), { desc = "Choose OURS (left)" } },
          { "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "Choose THEIRS (right)" } },
          { "n", "<leader>cb", actions.conflict_choose("base"), { desc = "Choose BASE" } },
          { "n", "<leader>ca", actions.conflict_choose("all"), { desc = "Choose ALL" } },
          { "n", "[x", actions.prev_conflict, { desc = "Prev conflict" } },
          { "n", "]x", actions.next_conflict, { desc = "Next conflict" } },
        },
      },
    })

    -- :Review [pr_number]
    -- gh CLIでPR情報を取得 → ブランチをcheckout → diffviewでベースとの差分を表示
    vim.api.nvim_create_user_command("Review", function(opts)
      local pr_number = opts.args ~= "" and opts.args or nil

      -- PR番号が無ければ gh pr list で選ばせる (fzf経由)
      if not pr_number then
        vim.fn.jobstart(
          'gh pr list --limit 30 --json number,title,headRefName,baseRefName --jq \'.[] | "#\\(.number) \\(.title) [\\(.headRefName) → \\(.baseRefName)]"\'',
          {
            stdout_buffered = true,
            on_stdout = function(_, data)
              -- 空行を除去
              local items = vim.tbl_filter(function(line)
                return line ~= ""
              end, data or {})

              if #items == 0 then
                vim.schedule(function()
                  vim.notify("Review: オープンなPRがありません", vim.log.levels.WARN)
                end)
                return
              end

              vim.schedule(function()
                vim.ui.select(items, { prompt = "Review するPRを選択:" }, function(choice)
                  if not choice then
                    return
                  end
                  local num = choice:match("^#(%d+)")
                  if num then
                    vim.cmd("Review " .. num)
                  end
                end)
              end)
            end,
          }
        )
        return
      end

      -- PR情報を取得してdiffviewを開く
      vim.fn.jobstart(
        "gh pr view " .. pr_number .. " --json baseRefName,headRefName --jq '.baseRefName + \" \" + .headRefName'",
        {
          stdout_buffered = true,
          on_stdout = function(_, data)
            local line = (data and data[1]) or ""
            local base, head = line:match("^(%S+)%s+(%S+)")
            if not base then
              vim.schedule(function()
                vim.notify("Review: PR #" .. pr_number .. " の情報を取得できませんでした", vim.log.levels.ERROR)
              end)
              return
            end

            -- headブランチをcheckout
            vim.fn.jobstart("gh pr checkout " .. pr_number, {
              on_exit = function(_, code)
                vim.schedule(function()
                  if code ~= 0 then
                    vim.notify("Review: checkout に失敗しました", vim.log.levels.ERROR)
                    return
                  end
                  -- origin/base...HEAD の差分をdiffviewで表示
                  vim.cmd("DiffviewOpen origin/" .. base .. "...HEAD")
                  vim.notify("Review: PR #" .. pr_number .. " (" .. head .. " → " .. base .. ")")
                end)
              end,
            })
          end,
        }
      )
    end, {
      nargs = "?",
      desc = "Open PR diff in diffview (optionally specify PR number)",
    })

    -- :ReviewClose
    vim.api.nvim_create_user_command("ReviewClose", function()
      vim.cmd("DiffviewClose")
    end, { desc = "Close review diffview" })
  end,
}
