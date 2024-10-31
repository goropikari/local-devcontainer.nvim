local M = {
  config = nil,
}

local function default_cmd()
  if vim.fn.executable('wezterm') == 1 then
    return '/usr/bin/wezterm cli spawn --'
  elseif vim.fn.executable('wt.exe') then -- windows terminal
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
      [[--additional-features='{"ghcr.io/goropikari/devcontainer-feature/neovim:1": {}, "ghcr.io/devcontainers/features/sshd:1": {}}']],
    },
  },
  cmd = default_cmd(),
}

function M._define_command()
  local commands = {
    -- { 'DevContainerUp',        require('local-devcontainer').up },
  }
  for _, v in ipairs(commands) do
    local cmd, action = v[1], v[2]
    vim.api.nvim_create_user_command(cmd, action, {})
  end
end

function M._update_setting(opts)
  M.config = vim.tbl_extend('force', DEFAULT_CONFIG, opts or {})
end

function M.show_config()
  vim.print(M.config)
end

return M
