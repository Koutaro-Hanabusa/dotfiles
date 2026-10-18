local M = {}
local winbar = "%{v:lua.require'column_ruler'.render()}"

function M.render()
  local win = vim.api.nvim_get_current_win()
  local offset = vim.fn.getwininfo(win)[1].textoff
  local width = vim.api.nvim_win_get_width(win) - offset
  local left = vim.fn.winsaveview().leftcol
  local ruler = {}
  for i = 1, width do
    ruler[i] = " "
  end
  for column = math.ceil((left + 1) / 10) * 10, left + width, 10 do
    local label = tostring(column)
    for i = 1, #label do
      local position = column - left - #label + i
      if position > 0 and position <= width then
        ruler[position] = label:sub(i, i)
      end
    end
  end
  -- %{} drops one leading space from the returned string.
  return string.rep(" ", offset + 1) .. table.concat(ruler)
end

function M.setup()
  local function update()
    local win = vim.api.nvim_get_current_win()
    local current = vim.wo[win].winbar
    local normal = vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
      and vim.api.nvim_win_get_config(win).relative == ""
    if normal then
      if current == "" then
        vim.wo[win].winbar = winbar
      end
    elseif current == winbar then
      vim.wo[win].winbar = ""
    end
  end
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinNew", "TermOpen" }, {
    callback = update,
  })
  vim.api.nvim_create_autocmd("OptionSet", {
    pattern = "buftype",
    callback = update,
  })
  vim.api.nvim_exec_autocmds("WinEnter", {})
end

return M
