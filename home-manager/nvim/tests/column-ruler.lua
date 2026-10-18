vim.opt.rtp:prepend(vim.fn.getcwd() .. "/home-manager/nvim")
vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
local ruler = require("column_ruler")
ruler.setup()

local function bar(win)
  return vim.api.nvim_eval_statusline(vim.wo[win].winbar, {
    winid = win, use_winbar = true, maxwidth = vim.api.nvim_win_get_width(win),
  }).str
end

local first = vim.api.nvim_get_current_win()
local offset = vim.fn.getwininfo(first)[1].textoff
assert(bar(first):sub(offset + 9, offset + 10) == "10", "column 10 is misaligned")
assert(#bar(first) == vim.api.nvim_win_get_width(first), "ruler width is wrong")
vim.opt.number = false
vim.opt.signcolumn = "no"
assert(vim.api.nvim_win_get_width(first) - vim.fn.getwininfo(first)[1].textoff == 80, "test window must have 80 text columns")
assert(bar(first):sub(-2) == "80", "column 80 is missing at the right edge")
vim.opt.number = true
vim.opt.signcolumn = "yes"

vim.api.nvim_buf_set_lines(0, 0, -1, false, { string.rep("x", 200) })
vim.fn.winrestview({ leftcol = 25 })
assert(bar(first):sub(offset + 4, offset + 5) == "30", "horizontal scroll is misaligned")

vim.cmd("vsplit")
local second = vim.api.nvim_get_current_win()
vim.fn.winrestview({ leftcol = 0 })
vim.api.nvim_win_call(first, function()
  vim.fn.winrestview({ leftcol = 25 })
end)
assert(bar(first):sub(offset + 4, offset + 5) == "30", "inactive split lost its scroll position")
local second_offset = vim.fn.getwininfo(second)[1].textoff
assert(bar(second):sub(second_offset + 9, second_offset + 10) == "10", "split ruler is misaligned")
assert(#bar(second) == vim.api.nvim_win_get_width(second), "split ruler width is wrong")

vim.cmd("enew")
vim.bo.buftype = "nofile"
assert(vim.wo.winbar == "", "special buffer has a ruler")

vim.cmd("enew")
vim.api.nvim_exec_autocmds("BufWinEnter", {})
vim.wo.winbar = "custom"
vim.api.nvim_exec_autocmds("WinEnter", {})
assert(vim.wo.winbar == "custom", "existing winbar was overwritten")

local float = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
  relative = "editor", row = 1, col = 1, width = 20, height = 2,
})
vim.api.nvim_exec_autocmds("WinEnter", {})
assert(vim.wo[float].winbar == "", "floating window has a ruler")
