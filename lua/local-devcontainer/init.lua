local M = {}

local settings = require('local-devcontainer.settings')

function M.setup(opts)
  settings._update_setting(opts)
  settings._define_command()
end

M.up = require('local-devcontainer.devcontainer').devcontainer_up

M.show_config = settings.show_config

return M
