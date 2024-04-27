local M = {
  config = nil,
}

local function default_cmd()
  if vim.fn.executable 'wezterm' == 1 then
    return 'wezterm cli spawn --'
  elseif vim.fn.executable 'wt.exe' then -- windows terminal
    return 'cmd.exe /c "wt.exe" -w 0 nt bash -c'
  end
  return ''
end

local DEFAULT_CONFIG = {
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
      -- '--mount type=bind,source=$HOME/.config/nvim,target=/home/vscode/.config/nvim',
      [[--additional-features='{"ghcr.io/goropikari/devcontainer-feature/neovim:1": {}, "ghcr.io/devcontainers/features/sshd:1": {}}']],
    },
  },
  cmd = default_cmd(),
}
M.config = DEFAULT_CONFIG

function M._define_command()
  local commands = {
    -- { 'LCConnect',        require('local-devcontainer').connect_container },
    -- { 'LCShowConfig',     M.show_config },
    -- { 'LCForwardSSHSock', require('local-devcontainer').forward_ssh_sock },
  }
  for _, v in ipairs(commands) do
    local cmd, action = v[1], v[2]
    vim.api.nvim_create_user_command(cmd, action, {})
  end
end

function M._update_setting(opts)
  for key, value in pairs(DEFAULT_CONFIG) do
    local v2 = opts[key]
    if v2 then
      if type(v2) == 'table' then
        print(vim.inspect(v2))
        M.config[key] = vim.fn.extend(value, v2)
      else
        M.config[key] = v2
      end
    end
  end
end

function M.show_config()
  print(vim.inspect(M.config))
end

return M