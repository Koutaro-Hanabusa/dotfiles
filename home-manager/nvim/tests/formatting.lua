vim.opt.runtimepath:prepend(vim.fn.expand("~/.local/share/nvim/lazy/conform.nvim"))

local base = vim.fn.tempname()
vim.fn.mkdir(base, "p")
base = vim.uv.fs_realpath(base)
local repo = base .. "/repo"
vim.fn.mkdir(repo .. "/node_modules/.bin", "p")
vim.fn.mkdir(repo .. "/packages/web/src", "p")
vim.fn.mkdir(repo .. "/packages/nested/src", "p")
vim.fn.writefile({}, repo .. "/.git") -- Worktrees use a file here.

local function write(path, lines)
  vim.fn.writefile(lines, path)
end

local function executable(path)
  write(path, { "#!/bin/sh", "cat" })
  assert(vim.uv.fs_chmod(path, 493))
end

local function buffer(path, ft)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, path)
  vim.bo[bufnr].filetype = ft
  return bufnr
end

write(repo .. "/package.json", { '{"devDependencies":{"vite-plus":"1.0.0"}}' })
executable(repo .. "/node_modules/.bin/vp")
executable(repo .. "/node_modules/.bin/biome") -- Stale binary is not a declaration.
executable(repo .. "/node_modules/.bin/oxfmt")

local config = dofile("home-manager/nvim/lua/plugins/conform.lua")
config.config()
local conform = require("conform")
vim.api.nvim_set_current_dir(base)

local root_buffer = buffer(repo .. "/src/app.ts", "typescript")
assert(vim.deep_equal(conform.list_formatters_for_buffer(root_buffer), { "vite_plus" }))
assert(conform.get_formatter_info("vite_plus", root_buffer).command == repo .. "/node_modules/.bin/vp")
assert(not conform.get_formatter_info("prettier", root_buffer).available)
assert(conform.get_formatter_config("vite_plus", root_buffer).stdin == true)
assert(conform.formatters_by_ft.typescript(root_buffer).lsp_format == "never")

write(repo .. "/packages/web/package.json", { '{"devDependencies":{"oxfmt":"1.0.0","@biomejs/biome":"1.0.0"}}' })
local nested = buffer(repo .. "/packages/web/src/app.ts", "typescript")
assert(vim.deep_equal(conform.list_formatters_for_buffer(nested), { "oxfmt" }))
assert(conform.get_formatter_info("oxfmt", nested).command == repo .. "/node_modules/.bin/oxfmt")

write(repo .. "/packages/nested/package.json", { '{"devDependencies":{"@biomejs/biome":"1.0.0"}}' })
local missing = buffer(repo .. "/packages/nested/src/app.ts", "typescript")
assert(vim.deep_equal(conform.list_formatters_for_buffer(missing), { "biome" }))
assert(conform.get_formatter_info("biome", missing).command == repo .. "/node_modules/.bin/biome")
assert(vim.uv.fs_unlink(repo .. "/node_modules/.bin/biome"))
assert(vim.tbl_isempty(conform.list_formatters_for_buffer(missing)))
assert(conform.formatters_by_ft.typescript(missing).lsp_format == "never")

vim.fn.mkdir(repo .. "/packages/nested/src/subrepo", "p")
write(repo .. "/packages/nested/src/subrepo/.git", { "gitdir: /private/tmp/elsewhere" })
local isolated = buffer(repo .. "/packages/nested/src/subrepo/app.ts", "typescript")
assert(vim.tbl_isempty(conform.list_formatters_for_buffer(isolated)))

local php = buffer(repo .. "/app.php", "php")
assert(vim.tbl_isempty(conform.list_formatters_for_buffer(php)))
assert(not conform.get_formatter_info("pint", php).available)
vim.fn.mkdir(repo .. "/vendor/bin", "p")
executable(repo .. "/vendor/bin/pint")
assert(vim.deep_equal(conform.list_formatters_for_buffer(php), { "pint" }))

vim.fn.delete(base, "rf")
print("formatting selection: OK")
