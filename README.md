# local-devcontainer.nvim

Launch devcontainer from neovim and connect the container via ssh.

![demo](docs/demo.gif)

# Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'goropikari/local-devcontainer.nvim',
  enabled = vim.fn.executable('devcontainer') == 1,
  opts = {
    -- some opts
  },
}
```

# Required
devcontainer cli, socat are required.

```bash
npm install -g @devcontainers/cli

sudo apt-get install -y socat
```


# Setup

default parameter

```lua
require('local-devcontainer').setup({
  ssh = {
    user = 'vscode',
    host = 'localhost',
    port = 2222,
    public_key_path = '~/.ssh/id_rsa.pub',
    secret_key_path = '~/.ssh/id_rsa',
  },
  devcontainer = {
    path = 'devcontainer',
    args = {
      '--workspace-folder=.',
      [[--additional-features='{"ghcr.io/goropikari/devcontainer-feature/neovim:1": {}, "ghcr.io/devcontainers/features/sshd:1": {}}']],
    }
  },
  cmd = 'wezterm cli spawn --', -- windows: 'cmd.exe /c "wt.exe" -w 0 nt bash -c'
})
```

# Usage

```lua
lua require('local-devcontainer').up()
```

```lua
vim.api.nvim_create_user_command(
  "DevContainerUp",
  require('local-devcontainer').up,
  {}
)
```


# TODO

- [ ] When neovim supports vim's remote_foreground, stop creating terminal tabs and move to it.
