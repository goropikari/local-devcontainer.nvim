local M = {}

local default_config = {
  ssh = {
    host_sock_dir = vim.fn.stdpath('data') .. '/local-devcontainer.nvim/ssh',
    remote_sock_dir = '/tmp/local-devcontainer/ssh',
    sock_file_name = 'ssh_auth.sock',
  },
  devcontainer = {
    path = 'devcontainer',
    args = {
      '--workspace-folder=.',
      [[--additional-features='{"ghcr.io/goropikari/devcontainer-feature/neovim:1": {}}]],
    },
  },
  cmd = (function()
    if vim.fn.has('wsl') == 1 then
      return 'cmd.exe /c "wt.exe" -w 0 nt bash -c'
    else
      return 'alacritty -e'
    end
  end)(),
}
local global_internal_config = {}

local function get_remote_sock_path()
  local ssh = global_internal_config.ssh
  return ssh.remote_sock_dir .. '/' .. ssh.sock_file_name
end

local function get_host_sock_path()
  local ssh = global_internal_config.ssh
  return ssh.host_sock_dir .. '/' .. ssh.sock_file_name
end

local state = {
  bufnr = -1,
  winid = -1,
}

---@param bufnr number
---@param winid number
function move_bottom(winid, bufnr)
  if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
    local last_num = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(winid, { last_num, 0 })
  end
end

local function _setup_auth_sock()
  local sock_dir = global_internal_config.ssh.host_sock_dir
  vim.fn.mkdir(sock_dir, 'p')

  vim
    .system({ 'ls', get_host_sock_path() }, {}, function(obj)
      if obj.code ~= 0 then
        vim
          .system({
            'socat',
            os.getenv('SSH_AUTH_SOCK'),
            'unix-listen:' .. get_host_sock_path() .. ',fork',
          })
          :wait()
      end
    end)
    :wait()
end

local function _devcontainer_up()
  local host_sock_dir = global_internal_config.ssh.host_sock_dir
  local remote_sock_dir = global_internal_config.ssh.remote_sock_dir

  local args = global_internal_config.devcontainer.args or {}
  local cmd = {
    global_internal_config.devcontainer.path,
    'up',
    '--mount',
    'type=bind,source=' .. get_host_sock_path() .. ',target=' .. get_remote_sock_path(),
    '--remote-env',
    'SSH_AUTH_SOCK=' .. get_remote_sock_path(),
  }
  vim.list_extend(cmd, args)

  state.winid = vim.api.nvim_open_win(state.bufnr, false, {
    split = 'below',
    height = math.floor(vim.o.lines / 4),
  })

  vim.system(cmd, {
    stderr = function(_, data)
      -- progress of devcontainer setup
      vim.schedule(function()
        if data then
          data = string.gsub(data, '\r\n', '\n')
          vim.api.nvim_buf_set_lines(state.bufnr, -1, -1, false, vim.fn.split(data, '\n'))
          move_bottom(state.winid, state.bufnr)
        end
      end)
    end,
  }, function(obj)
    if obj.code ~= 0 then
      vim.notify('exit code: ' .. tostring(obj.code), vim.log.levels.ERROR)
      return
    end
    vim.schedule(function()
      local stdout = obj.stdout
      if stdout then
        local res = vim.json.decode(stdout)
        vim.api.nvim_buf_set_lines(state.bufnr, -1, -1, false, vim.fn.split(vim.inspect(res), '\n'))
        move_bottom(state.winid, state.bufnr)

        if res.outcome ~= 'success' then
          return
        end
        local containerID = res.containerId

        local ret = vim
          .system({
            'docker',
            'exec',
            containerID,
            'grep',
            'SSH_AUTH_SOCK',
            '/etc/bash.bashrc',
          }, {})
          :wait()

        vim.system(ret.code ~= 0 and {
          'docker',
          'exec',
          '-u',
          'root',
          containerID,
          'bash',
          '-c',
          'echo export SSH_AUTH_SOCK=' .. get_remote_sock_path() .. '>> /etc/bash.bashrc',
        } or { 'echo', 'foo' }, {}, function(obj2)
          if obj2.code ~= 0 then
            vim.notify('exit code: ' .. tostring(obj2.code), vim.log.levels.ERROR)
            return
          end
          vim.system(
            vim
              .iter({
                vim.split(global_internal_config.cmd, ' '),
                'devcontainer',
                'exec',
                '--workspace-folder=.',
                'bash',
              })
              :flatten()
              :totable(),
            {},
            function(obj3)
              if obj3.code ~= 0 then
                vim.notify('exit code: ' .. tostring(obj3.code), vim.log.levels.ERROR)
                return
              end
            end
          )
        end)
      end
    end)
  end)
end

local function devcontainer_up()
  _setup_auth_sock()
  _devcontainer_up()
end

function M.setup(opts)
  global_internal_config = vim.tbl_deep_extend('force', default_config, opts or {})
  state.bufnr = vim.api.nvim_create_buf(false, true)
end

function M.show_config()
  vim.print(global_internal_config)
end

M.up = devcontainer_up

return M
