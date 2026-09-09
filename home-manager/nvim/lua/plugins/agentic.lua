return {
  "carlos-algms/agentic.nvim",
  opts = {
    provider = "codex-acp",
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("agentic").toggle()
      end,
      mode = { "n", "v" },
      desc = "Agentic: Toggle chat",
    },
    {
      "<leader>as",
      function()
        require("agentic").add_selection_or_file_to_context()
      end,
      mode = { "n", "v" },
      desc = "Agentic: Add file or selection",
    },
    {
      "<leader>an",
      function()
        require("agentic").new_session()
      end,
      mode = { "n", "v" },
      desc = "Agentic: New session",
    },
    {
      "<leader>ar",
      function()
        require("agentic").restore_session()
      end,
      mode = { "n", "v" },
      desc = "Agentic: Restore session",
    },
  },
}
