local M = {}
local buildsystem = {}

local cp_config = string.format("%s/cp_utils.json", vim.fn.stdpath("data"))

function M.init_buildsystem()
  local config_file = io.open(cp_config, 'rb')
  if not config_file then
    config_file = io.open(cp_config, 'w')
    config_file:write("{\"java\": [ [\"javac\", \"$filename\"], [\"java\", \"$base_filename\"] ]}")
    config_file:close()
    return
  end
  local content = config_file:read('*a')
  config_file:close()
  buildsystem = vim.fn.json_decode(content)
end

function Get_base_file(filename)
  local temp = -100
  local l = 0
  while temp ~= nil do
    temp = filename:find('.', l, true)
    if temp == nil then
      break
    end
    l = temp + 1
  end
  l = l - 3
  return filename:sub(0, -filename:len() + l)
end

function Get_file_dir(filename)
  local len = string.len(filename)

  local f_dir_till = -1

  for i = 0, len, 1 do
    if string.sub(filename, i, i) == '/' then
      f_dir_till = i
    end
  end

  return filename:sub(1, f_dir_till - 1)
end

function M.get_buildsystem()
  return buildsystem
end

function M.run(filetype, filename, configuration)
  if buildsystem[filetype] == nil then
    print('Build system not found')
    return
  end
  local base_fname = Get_base_file(filename)
  local file_dir = Get_file_dir(filename)
  local commands = {}
  local itr = 1
  while buildsystem[filetype][itr] ~= nil do
    commands[itr] = buildsystem[filetype][itr]
    itr = itr + 1
  end
  for i = 1, itr - 1, 1 do
    local j = 1
    while commands[i][j] ~= nil do
      commands[i][j] = commands[i][j]:gsub('$filename', filename, 1)
      commands[i][j] = commands[i][j]:gsub('$base_filename', base_fname, 1)
      commands[i][j] = commands[i][j]:gsub('$f_dir', file_dir, 1)
      j = j + 1
    end
  end
  vim.api.nvim_buf_set_lines(configuration.error_bufnr, 0, -1, false, { "Error:" })
  vim.api.nvim_buf_set_lines(configuration.output_bufnr, 0, -1, false, { "Output:" })
  local start_clock = os.clock()
  for i = 1, itr - 1, 1 do
    Run_command(commands[i], configuration)
  end
  local diff = os.clock() - start_clock
  vim.api.nvim_buf_set_lines(configuration.output_bufnr, -1, -1, false, { "Execution Time: ", tostring(diff) })
end

function Run_command(command, configuration, call_back)
  local input = ""
  if configuration.input_bufnr then
    input = ""
    for _, v in pairs(vim.api.nvim_buf_get_lines(configuration.input_bufnr, 0, -1, false)) do
      input = input .. v .. "\n"
    end
  end
  local jobid = vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(configuration.output_bufnr, -1, -1, false, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(configuration.error_bufnr, -1, -1, false, data)
      end
    end,
  })
  if configuration.input_bufnr then
    vim.fn.jobsend(jobid, input)
    vim.fn.jobclose(jobid, 'stdin')
  end
  vim.fn.jobwait({ jobid }, 10000)
  if call_back then
    Run_command(call_back.command, call_back.configuration, nil)
  end
end

return M
