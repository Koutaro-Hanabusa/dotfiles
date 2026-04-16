-- :Review でPR選択→checkout→diff→レビューモードまでワンコマンドで行うワークフロー
return {
  dir = "~",
  name = "review-workflow",
  dependencies = {
    "pwntester/octo.nvim",
    "nvim-telescope/telescope.nvim",
  },
  cmd = { "Review", "ReviewSubmit", "ReviewClose" },
  keys = {
    { "<leader>rv", "<cmd>Review<CR>", desc = "Review: Start PR review" },
    { "<leader>rx", "<cmd>ReviewClose<CR>", desc = "Review: Close review" },
  },
  config = function()
    local _review_pending = false

    -- octo PR バッファが開いたら自動でcheckout + レビュー開始
    local function setup_auto_review()
      if _review_pending then
        return
      end
      _review_pending = true

      local group = vim.api.nvim_create_augroup("ReviewAutoStart", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "octo",
        once = true,
        callback = function()
          _review_pending = false
          -- octo バッファがGitHubからデータ取得完了を待ってからcheckout→review start
          vim.defer_fn(function()
            -- PRをcheckoutしてからレビュー開始
            local ok_checkout, err_checkout = pcall(vim.cmd, "Octo pr checkout")
            if not ok_checkout then
              vim.notify("Review checkout: " .. tostring(err_checkout), vim.log.levels.WARN)
            end
            -- checkout後にレビュー開始（少し待つ）
            vim.defer_fn(function()
              local ok, err = pcall(vim.cmd, "Octo review start")
              if not ok then
                vim.notify("Review start: " .. tostring(err), vim.log.levels.WARN)
              end
            end, 1000)
          end, 1500)
        end,
      })

      -- 10秒以内にoctoバッファが開かなかったらクリーンアップ
      vim.defer_fn(function()
        if _review_pending then
          _review_pending = false
          pcall(vim.api.nvim_del_augroup_by_name, "ReviewAutoStart")
        end
      end, 10000)
    end

    -- :Review [pr_number]
    vim.api.nvim_create_user_command("Review", function(opts)
      local pr_number = opts.args ~= "" and opts.args or nil

      -- 既にoctoバッファにいる場合はそのままレビュー開始
      if vim.bo.filetype == "octo" then
        vim.cmd("Octo review start")
        return
      end

      setup_auto_review()

      if pr_number then
        vim.cmd("Octo pr " .. pr_number)
      else
        vim.cmd("Octo pr list")
      end
    end, {
      nargs = "?",
      desc = "Start PR review (optionally specify PR number)",
    })

    -- :ReviewSubmit
    vim.api.nvim_create_user_command("ReviewSubmit", function()
      vim.cmd("Octo review submit")
    end, { desc = "Submit the current review" })

    -- :ReviewClose
    vim.api.nvim_create_user_command("ReviewClose", function()
      pcall(vim.cmd, "Octo review discard")
      -- octoバッファを閉じる
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
          if ft == "octo" then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
      end
    end, { desc = "Discard review and close" })
  end,
}
