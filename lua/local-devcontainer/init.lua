local termitary = require('termitary-mod')

local M = {}

local function default_cmd()
  if vim.fn.executable('wezterm') == 1 then
    return '/usr/bin/wezterm cli spawn --'
  elseif vim.fn.executable('wt.exe') then -- windows terminal
    return 'cmd.exe /c "wt.exe" -w 0 nt bash -c'
  end
  return ''
end

local default_config = {
  ssh = {
    user = 'vscode',
    host = 'localhost',
    port = 2222,
    public_key_path = '~/.ssh/id_rsa.pub',
    secret_key_path = '~/.ssh/id_rsa',
  },
  neovim = {
    remote_path = '/opt/nvim/squashfs-root/usr/bin/nvim',
  },
  devcontainer = {
    path = 'devcontainer',
    args = {
      '--workspace-folder=.',
      [[--additional-features='{"ghcr.io/goropikari/devcontainer-feature/neovim:1": {}, "ghcr.io/devcontainers/features/sshd:1": {}}']],
    },
  },
  cmd = default_cmd(),
}
local global_internal_config = {}

local function define_command()
  local commands = {
    -- { 'DevContainerUp',        require('local-devcontainer').up },
  }
  for _, v in ipairs(commands) do
    local cmd, action = v[1], v[2]
    vim.api.nvim_create_user_command(cmd, action, {})
  end
end

function M.setup(opts)
  global_internal_config = vim.tbl_extend('force', default_config, opts or {})
  define_command()
end

function M.show_config()
  vim.print(global_internal_config)
end

local function script_path()
  local str = debug.getinfo(2, 'S').source:sub(2)
  return str:match('(.*/)')
end

local function _devcontainer_up()
  local args = global_internal_config.devcontainer.args or {}
  local cmd = {
    global_internal_config.devcontainer.path,
    'up',
  }

  for _, v in pairs(args) do
    table.insert(cmd, v)
  end
  termitary.type(cmd)
end

local function _setup_ssh()
  termitary.type({
    'bash',
    script_path() .. '../../sh/setup.sh',
    global_internal_config.ssh.public_key_path,
    global_internal_config.ssh.secret_key_path,
    global_internal_config.ssh.port,
    global_internal_config.ssh.user,
    '"' .. global_internal_config.cmd .. '"',
  })

  vim.notify(vim.fn.join({
    'ssh -t -i',
    global_internal_config.ssh.secret_key_path,
    '-o NoHostAuthenticationForLocalhost=yes',
    '-o UserKnownHostsFile=/dev/null',
    '-o GlobalKnownHostsFile=/dev/null',
    '-p',
    global_internal_config.ssh.port,
    global_internal_config.ssh.user .. '@' .. global_internal_config.ssh.host,
  }, ' '))
end

local function devcontainer_up()
  _devcontainer_up()
  _setup_ssh()
end

M.up = devcontainer_up

return M
