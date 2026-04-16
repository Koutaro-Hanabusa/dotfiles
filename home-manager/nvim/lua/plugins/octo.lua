return {
  "pwntester/octo.nvim",
  cmd = { "Octo", "Review", "ReviewSubmit", "ReviewClose" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>rv", "<cmd>Review<CR>", desc = "Review: Start PR review" },
    { "<leader>rx", "<cmd>ReviewClose<CR>", desc = "Review: Close review" },
    { "<leader>rs", "<cmd>ReviewSubmit<CR>", desc = "Review: Submit" },
    { "<leader>ol", "<cmd>Octo pr list<CR>", desc = "Octo: PR list" },
    { "<leader>oi", "<cmd>Octo issue list<CR>", desc = "Octo: Issue list" },
  },
  config = function()
    require("octo").setup({
      picker = "telescope",
      enable_builtin = true,
      default_remote = { "upstream", "origin" },
      default_merge_method = "squash",
      suppress_missing_scope = {
        projects_v2 = true,
      },
    })

    -- Keymaps for quick access
    vim.keymap.set("n", "<leader>os", "<cmd>Octo search<CR>", { desc = "Octo: Search" })
    vim.keymap.set("n", "<leader>on", "<cmd>Octo notification list<CR>", { desc = "Octo: Notifications" })

    -- PR operations
    vim.keymap.set("n", "<leader>op", "<cmd>Octo pr checkout<CR>", { desc = "Octo: PR checkout" })
    vim.keymap.set("n", "<leader>od", "<cmd>Octo pr diff<CR>", { desc = "Octo: PR diff" })
    vim.keymap.set("n", "<leader>oc", "<cmd>Octo pr changes<CR>", { desc = "Octo: PR changes" })
    vim.keymap.set("n", "<leader>om", "<cmd>Octo pr merge<CR>", { desc = "Octo: PR merge" })
    vim.keymap.set("n", "<leader>ok", "<cmd>Octo pr checks<CR>", { desc = "Octo: PR checks" })

    -- Review (octo review resume/comments are useful during review)
    vim.keymap.set("n", "<leader>rr", "<cmd>Octo review resume<CR>", { desc = "Octo: Resume review" })
    vim.keymap.set("n", "<leader>rc", "<cmd>Octo review comments<CR>", { desc = "Octo: Review comments" })

    -- Comments & threads
    vim.keymap.set("n", "<leader>oa", "<cmd>Octo comment add<CR>", { desc = "Octo: Add comment" })
    vim.keymap.set("n", "<leader>otr", "<cmd>Octo thread resolve<CR>", { desc = "Octo: Resolve thread" })
    vim.keymap.set("n", "<leader>otu", "<cmd>Octo thread unresolve<CR>", { desc = "Octo: Unresolve thread" })

    -- :Review [pr_number] — PRを開いてocto reviewを開始
    vim.api.nvim_create_user_command("Review", function(opts)
      local pr_number = opts.args ~= "" and opts.args or nil

      -- 既にoctoバッファにいる場合はそのままレビュー開始
      if vim.bo.filetype == "octo" then
        vim.cmd("Octo review start")
        return
      end

      if pr_number then
        -- PR番号指定: 直接開いてレビュー開始
        vim.cmd("Octo pr " .. pr_number)
        -- octoバッファが開いたらレビュー開始
        local group = vim.api.nvim_create_augroup("ReviewAutoStart", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
          group = group,
          pattern = "octo",
          once = true,
          callback = function()
            vim.defer_fn(function()
              pcall(vim.cmd, "Octo review start")
            end, 1500)
          end,
        })
      else
        -- PR番号なし: PR一覧を表示
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
