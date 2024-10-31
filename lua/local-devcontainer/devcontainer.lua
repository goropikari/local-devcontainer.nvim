local termitary = require('termitary-mod')

local M = {}

local settings = require('local-devcontainer.settings')

local function script_path()
  local str = debug.getinfo(2, 'S').source:sub(2)
  return str:match('(.*/)')
end

function M._devcontainer_up()
  local args = settings.config.devcontainer.args or {}
  local cmd = {
    settings.config.devcontainer.path,
    'up',
  }

  for _, v in pairs(args) do
    table.insert(cmd, v)
  end
  termitary.type(cmd)
end

function M._setup_ssh()
  termitary.type({
    'bash',
    script_path() .. '../../sh/setup.sh',
    settings.config.ssh.public_key_path,
    settings.config.ssh.secret_key_path,
    settings.config.ssh.port,
    settings.config.ssh.user,
    '"' .. settings.config.cmd .. '"',
  })

  if settings.config.cmd == '' then
    vim.notify(vim.fn.join({
      'ssh -t -i',
      settings.config.ssh.secret_key_path,
      '-o NoHostAuthenticationForLocalhost=yes',
      '-o UserKnownHostsFile=/dev/null',
      '-o GlobalKnownHostsFile=/dev/null',
      '-p',
      settings.config.ssh.port,
      settings.config.ssh.user .. '@' .. settings.config.ssh.host,
    }, ' '))
  end
end

function M.devcontainer_up()
  M._devcontainer_up()
  M._setup_ssh()
end

return M
