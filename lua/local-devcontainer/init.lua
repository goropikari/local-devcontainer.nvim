local M = {}

local default_config = {
  ssh = {
    public_key = '~/.ssh/id_rsa.pub',
  },
}
local config = {}

local state = {
  bufnr = -1,
  winid = -1,
  up_out = nil,
  container_id = '',
  config_dir = '',
}

local function split(s)
  return vim.split(s, ' ')
end

---@param bufnr number
---@param winid number
local function move_bottom(winid, bufnr)
  if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
    local last_num = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(winid, { last_num, 0 })
  end
end

local function get_config_dir()
  return vim.fn.stdpath('data') .. '/local-devcontainer.nvim/' .. vim.fn.sha256(vim.fn.getcwd())
end

---@param data string
local function logging(data)
  vim.schedule(function()
    vim.api.nvim_buf_set_lines(state.bufnr, -1, -1, false, vim.split(data, '\n'))
    move_bottom(state.winid, state.bufnr)
  end)
end

local function expand_vscode_var(input)
  input = string.gsub(input, '${file}', vim.fn.expand('%:p'))
  input = string.gsub(input, '${fileBasename}', vim.fn.expand('%:t'))
  input = string.gsub(input, '${fileBasenameNoExtension}', vim.fn.fnamemodify(vim.fn.expand('%:t'), ':r'))
  input = string.gsub(input, '${fileDirname}', vim.fn.expand('%:p:h'))
  input = string.gsub(input, '${fileExtname}', vim.fn.expand('%:e'))
  input = string.gsub(input, '${relativeFile}', vim.fn.expand('%:.'))
  input = string.gsub(input, '${relativeFileDirname}', vim.fn.fnamemodify(vim.fn.expand('%:.:h'), ':r'))
  input = string.gsub(input, '${workspaceFolder}', vim.fn.getcwd())
  input = string.gsub(input, '${workspaceFolderBasename}', vim.fn.fnamemodify(vim.fn.getcwd(), ':t'))
  input = string.gsub(input, '%${env:([%w_]+)}', function(env_name)
    return os.getenv(env_name) or ''
  end)
  return input
end

---@param input table
local function expand_vscode_var_tb(input)
  local s = vim.json.encode(input)
  s = expand_vscode_var(s)
  return vim.json.decode(s)
end

---@return table
local function read_configuration()
  local obj = vim.system({ 'devcontainer', 'read-configuration', '--workspace-folder=.' }):wait()
  if obj.code ~= 0 then
    vim.notify(obj.stderr)
    return {}
  end
  return vim.json.decode(obj.stdout)
end

---@param path string
---@return table
local function read_json(path)
  local file = io.open(path, 'r')
  if file ~= nil then
    local contents = file:read('*a')
    file:close()
    return vim.json.decode(contents)
  end
  return {}
end

---@return table
local function read_unite_config()
  return read_json(state.unite_config_path)
end

---@param tb table
local function write_unite_config(tb)
  local js = vim.json.encode(tb)
  local file = io.open(state.unite_config_path, 'w')
  if file ~= nil then
    file:write(js)
    file:close()
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', default_config, opts or {})
  config.ssh.public_key = vim.fn.expand(config.ssh.public_key)

  state.config_dir = get_config_dir()
  state.override_config_path = get_config_dir() .. '/override_config.jsonc'
  state.unite_config_path = get_config_dir() .. '/unite_config.jsonc'
end

local function setup_devcontainer_config()
  vim.fn.mkdir(state.config_dir, 'p')
  vim.system({ 'touch', state.override_config_path }):wait()
  vim.system({
    'unitejson',
    '.devcontainer/devcontainer.json',
    state.override_config_path,
  }, {}, function(out)
    if out.code ~= 0 then
      logging(out.stderr)
      return
    end
    local file = io.open(state.unite_config_path, 'w')
    if file ~= nil then
      file:write(out.stdout)
      file:close()
    end
  end)
end

local function setup_ssh()
  -- stylua: ignore
  vim.system(
    split('devcontainer exec --workspace-folder=. mkdir -p /home/vscode/.ssh'),
    {},
    function(out1)
      if out1.code ~= 0 then
        logging(out1.stderr)
        return
      end
      logging(out1.stdout)
      vim.system(
        {
          'docker',
          'cp',
          config.ssh.public_key,
          state.container_id .. ':/home/vscode/.ssh/authorized_keys',
        },
        {},
        function(out2)
          if out2.code ~= 0 then
            logging(out2.stderr)
            return
          end
          logging(out2.stdout)
          vim.system(
            {
              'bash',
              '-c',
              "devcontainer exec --workspace-folder=. bash -c 'chmod 644 /home/vscode/.ssh/authorized_keys'",
            },
            {},
            function(out3)
              if out3.code ~= 0 then
                logging(out3.stderr)
                return
              end
              logging(out3.stdout)
              vim.system(
                {
                  'bash',
                  '-c',
                  "devcontainer exec --workspace-folder=. bash -c 'chmod 700 /home/vscode/.ssh'",
                },
                {},
                function(out4)
                  if out4.code ~= 0 then
                    logging(out4.stderr)
                    return
                  end
                  logging(out4.stdout)
                  vim.system(
                    {
                      'docker',
                      'rename',
                      state.container_id,
                      'devc-' .. vim.fn.fnamemodify(vim.uv.cwd() or '', ':t'),
                    }
                  )
                end
              )
            end
          )
        end
      )
  end)
end

local function up(opts)
  state.bufnr = vim.api.nvim_create_buf(true, true)
  state.winid = vim.api.nvim_open_win(state.bufnr, false, { split = 'below', style = 'minimal' })

  opts = opts or {}
  setup_devcontainer_config()
  local cmd = split('devcontainer up --workspace-folder=. --override-config ' .. state.unite_config_path)
  if opts.restart then
    table.insert(cmd, '--remove-existing-container')
  end

  local cfg = read_configuration()
  if vim.tbl_get(cfg, 'configuration', 'dockerComposeFile') then
    write_unite_config(expand_vscode_var_tb(read_unite_config()))
  end
  -- vim.print(cmd)

  vim.system(cmd, {
    ---@diagnostic disable-next-line
    stderr = function(err, data)
      if data ~= nil then
        logging(data)
      end
    end,
  }, function(obj)
    if obj.code ~= 0 then
      logging(obj.stdout)
      logging(obj.stderr)
      return
    end
    local out = vim.json.decode(obj.stdout)
    logging(obj.stdout)
    state.up_out = out
    state.container_id = out.containerId
    setup_ssh()
  end)
end

local function show()
  vim.print(vim.inspect(config))
  vim.print(vim.inspect(state))
end

local function open_unite_config()
  vim.cmd(':e ' .. state.unite_config_path)
end

local function open_override_config()
  vim.fn.mkdir(state.config_dir, 'p')
  vim.cmd(':e ' .. state.override_config_path)
end

M.up = up
M.show = show
M.open_unite_config = open_unite_config

vim.api.nvim_create_user_command('DevContainerUp', function(opts)
  local args = split(opts.args)
  vim.print(args)
  local restart = #args ~= 0 and args[1] == 'restart' or false
  up({
    restart = restart,
  })
end, {
  nargs = '?',
})
vim.api.nvim_create_user_command('DevContainerEditOverrideConfig', open_override_config, {})

return M
