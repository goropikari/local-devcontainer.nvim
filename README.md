# local-devcontainer.nvim

Launch devcontainer from neovim.

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
devcontainer cli are required.

```bash
npm install -g @devcontainers/cli
go install github.com/goropikari/unitejson@latest
```


# Setup

default parameter

```lua
require('local-devcontainer').setup({
  ssh = {
    public_key_path = '~/.ssh/id_rsa.pub',
  },
})
```

# Usage

```lua
lua require('local-devcontainer').up()
```

`~/.ssh/config`
```
ForwardAgent yes

Host devc
    ProxyCommand /usr/bin/nc $(docker inspect $(docker inspect devc-$(basename $(pwd)) --format='{{.Config.Hostname}}') --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}') %p
    Port 2222
    User vscode
    NoHostAuthenticationForLocalhost yes
    UserKnownHostsFile /dev/null
    GlobalKnownHostsFile /dev/null
    StrictHostKeyChecking no
```

# TODO

- [ ] When neovim supports vim's remote_foreground, stop creating terminal tabs and move to it.
