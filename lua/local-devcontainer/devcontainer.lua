local termitary = require 'termitary-mod'

local M = {}

local cfg = require('local-devcontainer.settings').config

local function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

function M._devcontainer_up()
  local args = cfg.devcontainer.args or {}
  local cmd = {
    cfg.devcontainer.path,
    'up',
  }

  for _, v in pairs(args) do
    table.insert(cmd, v)
  end
  termitary.type(cmd)
end

function M._setup_ssh()
  termitary.type {
    'bash',
    script_path() .. '../../sh/setup.sh',
    cfg.ssh.public_key_path,
    cfg.ssh.secret_key_path,
    cfg.ssh.port,
    cfg.ssh.user,
    '"' .. cfg.cmd .. '"',
  }

  if cfg.cmd == '' then
    require('osc52').copy(vim.fn.join({
      'ssh -t -i',
      cfg.ssh.secret_key_path,
      '-o NoHostAuthenticationForLocalhost=yes',
      '-o UserKnownHostsFile=/dev/null',
      '-o GlobalKnownHostsFile=/dev/null',
      '-p',
      cfg.ssh.port,
      cfg.ssh.user .. '@' .. cfg.ssh.host,
    }, ' '))
  end
end

function M.devcontainer_up()
  M._devcontainer_up()
  M._setup_ssh()
end

return M
