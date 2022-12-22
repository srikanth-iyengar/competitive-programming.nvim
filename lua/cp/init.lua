local utils = require("cp.utils")
local runner = require("cp.run")

local M = {}
M.active = false

function M.focus_main()
  vim.api.nvim_set_current_win(M.main_win)
end

M.width = 45

local input_config = { line=2, col=vim.o.columns-M.width, minwidth=M.width, minheight=13, }
local output_config = { line=33.5, col=vim.o.columns-M.width, minwidth=M.width, minheight=13 }
local error_config = { line=33.5, col=vim.o.columns-M.width, minwidth=M.width, minheight=13 }

function M.setup()
  if M.active then
    M.show_all()
    return
  end
  M.active = true
  local bufin = vim.api.nvim_create_buf(false, false)
  local bufout = vim.api.nvim_create_buf(false, false)
  local buferr = vim.api.nvim_create_buf(false, false)
  M.main_win = vim.api.nvim_get_current_win()
  M.input = utils.create_plenary_win(bufin, "Input Block", input_config, M.main_win)
  M.output = utils.create_plenary_win(bufout, "Output Block", output_config, M.main_win)
  M.error = utils.create_plenary_win(buferr, "Error Block", error_config, M.main_win)
  runner.init_buildsystem()
  vim.api.nvim_win_close(M.error.win_id, true)
end

function M.destroy()
  for _, v in pairs(M) do
    if type(v) == "table" then
      if vim.api.nvim_win_is_valid(v.win_id) then
        vim.api.nvim_win_close(v.win_id, true)
      end
      if vim.api.nvim_buf_is_valid(v.bufnr) then
        vim.api.nvim_buf_delete(v.bufnr, {force=true})
      end
    end
  end
  M.active = false
end

function M.hide_all()
  for _, v in pairs(M) do
    if type(v) == "table" then
      if vim.api.nvim_win_is_valid(v.win_id) then
        vim.api.nvim_win_hide(v.win_id)
      end
    end
  end
end

function M.show_all()
  for k, v in pairs(M) do
    if type(v) == "table" then
      if not vim.api.nvim_win_is_valid(v.win_id) then
        if k == "input" then
          M.toggle_input()
        else if k == "output" then
            M.toggle_output()
          else
            M.toggle_error()
          end
        end
      end
    end
  end
end

function M.toggle_input()
  if vim.api.nvim_win_is_valid(M.input.win_id) then
    vim.api.nvim_win_close(M.input.win_id, true)
  else
    M.input = utils.create_plenary_win(M.input.bufnr, "Input Block", input_config, M.main_win)
  end
end

function M.toggle_output()
  if vim.api.nvim_win_is_valid(M.output.win_id) then
    vim.api.nvim_win_hide(M.output.win_id)
  else
    M.output = utils.create_plenary_win(M.output.bufnr, "Output Block", output_config, M.main_win)
  end
end

function M.toggle_error()
  if vim.api.nvim_win_is_valid(M.error.win_id) then
    vim.api.nvim_win_hide(M.error.win_id)
  else
    M.error = utils.create_plenary_win(M.error.bufnr, "Error Block", error_config, M.main_win)
  end
end

function M.focus_input()
  if not vim.api.nvim_win_is_valid(M.input.win_id) then
    M.input = utils.create_plenary_win(M.input.bufnr, "Input Block", input_config, M.main_win)
  end
  vim.api.nvim_set_current_win(M.input.win_id)
end

function M.focus_output()
  if not vim.api.nvim_win_is_valid(M.output.win_id) then
    M.output = utils.create_plenary_win(M.output.bufnr, "Output Block", output_config, M.main_win)
  end
  vim.api.nvim_set_current_win(M.output.win_id)
end

function M.focus_error()
  if not vim.api.nvim_win_is_valid(M.error.win_id) then
    M.error = utils.create_plenary_win(M.error.bufnr, "Error Block", error_config, M.main_win)
  end
  vim.api.nvim_set_current_win(M.error.win_id)
end

function M.run()
  local filetype = vim.bo.filetype
  local path = vim.api.nvim_buf_get_name(0)
  local filename = utils.get_file_name(path)
  runner.run(filetype, filename, {input_bufnr=M.input.bufnr, output_bufnr = M.output.bufnr, error_bufnr=M.error.bufnr})
end

function M.change_width(delta)
  local open_win = {}
  local configs = {input_config, output_config, error_config}
  if vim.api.nvim_win_is_valid(M.input.win_id) then
    M.toggle_input()
    table.insert(open_win, M.toggle_input)
  end
  if vim.api.nvim_win_is_valid(M.output.win_id) then
    M.toggle_output()
    table.insert(open_win, M.toggle_output)
  end
  if vim.api.nvim_win_is_valid(M.output.win_id) then
    M.toggle_error()
    table.insert(open_win, M.toggle_error)
  end
  M.width = M.width + delta
  for i = 1,3,1 do
    configs[i].minwidth = M.width
    configs[i].col = vim.o.columns - M.width
  end
  for _, v in pairs(open_win)do
    v()
  end
end


function M.edit_config()
  vim.cmd("e " .. string.format("%s/cp_utils.json", vim.fn.stdpath("data")))
end

function M.get_file_contents(path)
  local file = io.open(path, 'rb')
  if not file then
    return ""
  end
  local lines = file:lines()
  local content = {}
  for line in lines do
    table.insert(content, line)
  end
  file:close()
  return content
end

return M
