local status, popup = pcall(require, "plenary.popup")
if not status then
  return
end

local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
local M = {}

function M.create_plenary_win(bufnr, title, config, main_win)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, false)
  end
  local win_id, win = popup.create(bufnr,  {
      title = title or "Default title",
      line = config.line or 0,
      col = config.col or 0,
      minwidth = config.minwidth or 0,
      minheight = config.minheight or 0,
      borderchars = borderchars,
    })
  if title ~= "Configuration" then
    vim.api.nvim_buf_set_keymap (
      bufnr,
      "n",
      "<CR>",
      "<Cmd>lua require('cp').focus_main()<CR>",
      { silent=true }
      )

    vim.api.nvim_buf_set_option(bufnr, "filetype", "harpoon")
    vim.api.nvim_buf_set_option(bufnr, "buftype", "acwrite")
  end
  if main_win then
    vim.api.nvim_set_current_win(main_win)
  end
  return {
    bufnr = bufnr,
    win_id = win_id,
    win = win,
    show = true
  }
end

function M.get_file_name(filename)
  filename = filename:gsub("\\", "/", 1000)
  local temp = -100
  local l = 0
  while temp ~= nil do
    temp = filename:find("/", l, true)
    if temp == nil then
      break
    end
    l = temp + 1
  end
  return filename:sub(l, -1)
end

return M
