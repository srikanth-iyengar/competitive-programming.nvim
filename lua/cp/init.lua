local utils = require("cp.utils")
local runner = require("cp.run")

-- telescope requires
local builtin = require("telescope.builtin")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local M = {}
M.active = false
M.current_buildsystem = nil

function M.focus_main()
  vim.api.nvim_set_current_win(M.main_win)
end

M.width = 43

local input_config = { line = 2, col = vim.o.columns - M.width, minwidth = M.width, minheight = 13, maxheight = 13 }
local output_config = { line = 33.5, col = vim.o.columns - M.width, minwidth = M.width, minheight = 13, maxheight = 13 }
local error_config = { line = 33.5, col = vim.o.columns - M.width, minwidth = M.width, minheight = 13, maxheight = 13 }

function M.setup()
  if M.active then
    M.show_all()
    return
  end

  input_config.col = vim.o.columns - M.width
  output_config.col = vim.o.columns - M.width
  error_config.col = vim.o.columns - M.width

  output_config.minwidth = M.width
  input_config.minwidth = M.width
  error_config.minwidth = M.width


  output_config.minheight = math.floor(vim.o.lines / 2) - 4
  input_config.minheight = math.floor(vim.o.lines / 2) - 4
  error_config.minheight = math.floor(vim.o.lines / 2) - 4


  output_config.maxheight = math.floor(vim.o.lines / 2) - 4
  input_config.maxheight = math.floor(vim.o.lines / 2) - 4
  error_config.maxheight = math.floor(vim.o.lines / 2) - 4

  output_config.line = math.floor(vim.o.lines / 2) + 1
  error_config.line = math.floor(vim.o.lines / 2) + 1

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
        vim.api.nvim_buf_delete(v.bufnr, { force = true })
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
        else
          if k == "output" then
            M.toggle_output()
          else
            M.toggle_error()
          end
        end
      end
    end
  end
end

local function maximize_output()
  local itr = 0
  local call_back = {}
  if vim.api.nvim_win_is_valid(M.output.win_id) then
    M.toggle_output()
    table.insert(call_back, M.toggle_output)
  end
  if vim.api.nvim_win_is_valid(M.error.win_id) then
    M.toggle_error()
    table.insert(call_back, M.toggle_error)
  end
  output_config.line = 2
  error_config.line = 2
  output_config.minheight = vim.o.lines - 4
  error_config.minheight = vim.o.lines - 4
  output_config.maxheight = vim.o.lines - 4
  error_config.maxheight = vim.o.lines - 4
  for _, v in pairs(call_back) do
    v()
  end
end

local function minimize_output()
  local to_change = { output_config, error_config }
  local itr = 0
  local call_back = {}
  if vim.api.nvim_win_is_valid(M.output.win_id) then
    M.toggle_output()
    table.insert(call_back, M.toggle_output)
  end
  if vim.api.nvim_win_is_valid(M.error.win_id) then
    M.toggle_error()
    table.insert(call_back, M.toggle_error)
  end
  output_config.line = math.floor(vim.o.lines / 2) + 1
  error_config.line = math.floor(vim.o.lines / 2) + 1
  output_config.minheight = math.floor(vim.o.lines / 2) - 4
  error_config.minheight = math.floor(vim.o.lines / 2) - 4
  output_config.maxheight = math.floor(vim.o.lines / 2) - 4
  error_config.maxheight = math.floor(vim.o.lines / 2) - 4
  for _, v in pairs(call_back) do
    v()
  end
end

function M.toggle_input()
  if vim.api.nvim_win_is_valid(M.input.win_id) then
    vim.api.nvim_win_close(M.input.win_id, true)
    maximize_output()
  else
    minimize_output()
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
  local filetype = M.current_buildsystem or vim.bo.filetype
  local path = vim.api.nvim_buf_get_name(0)
  local filename = utils.get_file_name(path)
  runner.run(filetype, filename, { input_bufnr = M.input.bufnr, output_bufnr = M.output.bufnr, error_bufnr = M.error
  .bufnr }, path)
end

function M.change_width(delta)
  local open_win = {}
  local configs = { input_config, output_config, error_config }
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
  for i = 1, 3, 1 do
    configs[i].minwidth = M.width
    configs[i].col = vim.o.columns - M.width
  end
  for _, v in pairs(open_win) do
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

function M.change_buildsystem()
  runner.init_buildsystem()
  local opts = {}
  local systems = {}
  for k, _ in pairs(runner.get_buildsystem()) do
    table.insert(systems, k)
  end
  pickers.new(opts, {
    prompt_title = "Select a buildsystem",
    finder = finders.new_table {
      results = systems
    },
    sorter = config.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        M.current_buildsystem = selection[1]
      end)
      return true
    end
  }):find()
end

return M
