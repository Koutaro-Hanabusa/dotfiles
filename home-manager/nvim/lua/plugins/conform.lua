local web_filetypes = {
  "json",
  "jsonc",
  "yaml",
  "css",
  "scss",
  "html",
  "markdown",
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "vue",
  "graphql",
}

local web_tools = {
  { package = "vite-plus", binary = "vp", formatter = "vite_plus" },
  { package = "oxfmt", binary = "oxfmt", formatter = "oxfmt" },
  { package = "@biomejs/biome", binary = "biome", formatter = "biome" },
  { package = "prettier", binary = "prettier", formatter = "prettier" },
}

local function find_binary(dir, root, relative_path)
  while dir do
    local binary = dir .. "/" .. relative_path
    if vim.fn.executable(binary) == 1 then
      return binary
    end
    if dir == root then
      break
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

local function project_formatter(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return
  end

  local root = vim.fs.root(filename, ".git")
  local dir = vim.fs.dirname(filename)
  while dir do
    local package_file = dir .. "/package.json"
    if vim.fn.filereadable(package_file) == 1 then
      local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_file), "\n"))
      if not ok or type(package) ~= "table" then
        return
      end
      for _, tool in ipairs(web_tools) do
        local declared = (package.dependencies or {})[tool.package]
          or (package.devDependencies or {})[tool.package]
          or (package.optionalDependencies or {})[tool.package]
        if declared then
          local binary = find_binary(dir, root or dir, "node_modules/.bin/" .. tool.binary)
          if binary then
            return tool.formatter, binary, dir
          end
          return -- Declared but not installed: do not use another formatter.
        end
      end
    end
    if dir == root or (not root and vim.fn.filereadable(package_file) == 1) then
      break
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

local function web_formatter(bufnr)
  local formatter = project_formatter(bufnr)
  return formatter and { formatter, lsp_format = "never" } or { lsp_format = "never" }
end

local function project_command(name)
  return function(_, ctx)
    local formatter, binary = project_formatter(ctx.buf)
    return formatter == name and binary or ""
  end
end

local function pint_command(_, ctx)
  local filename = vim.api.nvim_buf_get_name(ctx.buf)
  if filename == "" then
    return ""
  end
  local root = vim.fs.root(filename, ".git") or vim.fs.root(filename, "composer.json")
  local dir = vim.fs.dirname(filename)
  return find_binary(dir, root or dir, "vendor/bin/pint") or ""
end

return {
  "stevearc/conform.nvim",
  config = function()
    local formatters_by_ft = {
      lua = { "stylua" },
      python = { "black" },
      go = { "gofmt" },
      php = function(bufnr)
        return pint_command(nil, { buf = bufnr }) ~= "" and { "pint" } or {}
      end,
    }
    for _, ft in ipairs(web_filetypes) do
      formatters_by_ft[ft] = web_formatter
    end

    require("conform").setup({
      formatters_by_ft = formatters_by_ft,
      formatters = {
        vite_plus = {
          command = project_command("vite_plus"),
          args = { "fmt", "--stdin-filepath", "$FILENAME" },
          stdin = true,
          cwd = function(_, ctx)
            local _, _, root = project_formatter(ctx.buf)
            return root
          end,
        },
        biome = { command = project_command("biome") },
        oxfmt = { command = project_command("oxfmt") },
        prettier = { command = project_command("prettier") },
        pint = { command = pint_command },
      },
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = { timeout_ms = 500 },
    })

    vim.keymap.set("n", "<leader>f", function()
      require("conform").format({ async = true })
    end, { desc = "Format buffer" })
  end,
}
