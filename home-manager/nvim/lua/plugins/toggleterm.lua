return {
  "akinsho/toggleterm.nvim",
  version = "*",
  lazy = true, -- 起動時に読み込まない
  keys = {
    { "<c-\\>", desc = "Toggle terminal" },
    { "<leader>t", desc = "Toggle terminal" },
    { "<leader>th", desc = "Horizontal terminal" },
    { "<leader>tv", desc = "Vertical terminal" },
    { "<leader>tf", desc = "Float terminal" },
    { "<leader>gh", desc = "Open gh-dash" },
    { "<leader>hd", desc = "Review working tree with Hunk" },
    { "<leader>hp", desc = "Review pull request with Hunk" },
    { "<leader>hn", desc = "Hunk: navigate to cursor" },
    { "<leader>hc", desc = "Hunk: add comment at cursor" },
    { "<leader>hR", desc = "Hunk: reload diff" },
    { "<leader>hN", desc = "Hunk: next comment" },
    { "<leader>hP", desc = "Hunk: prev comment" },
    { "<leader>hL", desc = "Hunk: list comments" },
  },
  config = function()
    require("toggleterm").setup({
      size = 10, -- Smaller terminal height
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true, -- insertモードで開始
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = false, -- insertモードを記憶しない
      direction = "horizontal", -- 'vertical' | 'horizontal' | 'tab' | 'float'
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      float_opts = {
        border = "curved",
        winblend = 0,
      },
    })

    -- キーマッピング
    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- <leader>t でターミナルをトグル
    keymap("n", "<leader>t", "<cmd>ToggleTerm<cr>", opts)
    keymap("t", "<leader>t", "<cmd>ToggleTerm<cr>", opts)

    -- ターミナルモードでESCでノーマルモードに戻る
    keymap("t", "<Esc>", [[<C-\><C-n>]], opts)
    keymap("t", "jj", [[<C-\><C-n>]], opts)

    -- 複数ターミナルの作成
    keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", opts)
    keymap("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", opts)
    keymap("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", opts)

    -- gh-dash用のカスタムターミナル
    local Terminal = require("toggleterm.terminal").Terminal
    local ghdash = Terminal:new({
      cmd = "gh dash",
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "curved",
      },
      on_open = function(term)
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
      end,
      on_close = function(_)
      end,
    })

    local function ghdash_toggle()
      ghdash:toggle()
    end

    keymap("n", "<leader>gh", ghdash_toggle, { desc = "Open gh-dash" })

    local function notify_hunk_controls()
      vim.notify("Hunk: ? = 操作一覧, q = 終了", vim.log.levels.INFO)
    end

    local hunk_worktree = Terminal:new({
      cmd = "hunk diff --watch",
      count = 2,
      dir = "git_dir",
      direction = "float",
      on_open = notify_hunk_controls,
      float_opts = {
        border = "curved",
      },
    })

    keymap("n", "<leader>hd", function()
      hunk_worktree:toggle()
    end, { desc = "Review working tree with Hunk" })

    keymap("n", "<leader>hp", function()
      vim.ui.input({ prompt = "PR number / URL / branch (blank = current): " }, function(target)
        if target == nil then
          return
        end

        local target_arg = target == "" and "" or " " .. vim.fn.shellescape(target)
        local hunk_pr = Terminal:new({
          cmd = "gh pr diff" .. target_arg .. " --patch | hunk patch -",
          count = 3,
          dir = "git_dir",
          direction = "float",
          on_open = notify_hunk_controls,
          float_opts = {
            border = "curved",
          },
        })
        hunk_pr:toggle()
      end)
    end, { desc = "Review pull request with Hunk" })

    -- Hunk session controls: nvim ↔ live hunk daemon
    local function hunk_repo_root()
      local cwd = vim.fn.getcwd()
      local out = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
      if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
        return cwd
      end
      return out[1]
    end

    local function hunk_rel_file(root)
      local abs = vim.fn.expand("%:p")
      if abs == "" then return nil end
      local rel = vim.fn.systemlist({ "git", "-C", root, "ls-files", "--full-name", "--", abs })[1]
      if rel and rel ~= "" then return rel end
      -- fallback: strip root prefix
      if abs:sub(1, #root + 1) == root .. "/" then
        return abs:sub(#root + 2)
      end
      return abs
    end

    local function run_hunk_session(args)
      local cmd = { "hunk", "session" }
      vim.list_extend(cmd, args)
      local result = vim.system(cmd, { text = true }):wait()
      if result.code ~= 0 then
        vim.notify("hunk: " .. (result.stderr or result.stdout or "failed"), vim.log.levels.ERROR)
        return nil
      end
      return result.stdout
    end

    keymap("n", "<leader>hn", function()
      local root = hunk_repo_root()
      local rel = hunk_rel_file(root)
      if not rel then
        vim.notify("Hunk: no file for current buffer", vim.log.levels.WARN)
        return
      end
      run_hunk_session({ "navigate", "--repo", root, "--file", rel, "--new-line", tostring(vim.fn.line(".")) })
    end, { desc = "Hunk: navigate to cursor" })

    keymap("n", "<leader>hc", function()
      local root = hunk_repo_root()
      local rel = hunk_rel_file(root)
      if not rel then
        vim.notify("Hunk: no file for current buffer", vim.log.levels.WARN)
        return
      end
      local lnum = vim.fn.line(".")
      vim.ui.input({ prompt = "Hunk comment: " }, function(summary)
        if not summary or summary == "" then return end
        run_hunk_session({
          "comment", "add",
          "--repo", root,
          "--file", rel,
          "--new-line", tostring(lnum),
          "--summary", summary,
          "--focus",
        })
      end)
    end, { desc = "Hunk: add comment at cursor" })

    keymap("n", "<leader>hR", function()
      run_hunk_session({ "reload", "--repo", hunk_repo_root(), "--", "diff" })
    end, { desc = "Hunk: reload diff" })

    keymap("n", "<leader>hN", function()
      run_hunk_session({ "navigate", "--repo", hunk_repo_root(), "--next-comment" })
    end, { desc = "Hunk: next comment" })

    keymap("n", "<leader>hP", function()
      run_hunk_session({ "navigate", "--repo", hunk_repo_root(), "--prev-comment" })
    end, { desc = "Hunk: prev comment" })

    keymap("n", "<leader>hL", function()
      local out = run_hunk_session({ "comment", "list", "--repo", hunk_repo_root() })
      if out and out ~= "" then
        vim.notify(out, vim.log.levels.INFO)
      else
        vim.notify("Hunk: no comments", vim.log.levels.INFO)
      end
    end, { desc = "Hunk: list comments" })
  end,
}
