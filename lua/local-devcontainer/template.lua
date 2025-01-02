local M = {}

---@return string[]
local function list_devcontainer_template_path()
  local paths = vim.fs.find({
    'devcontainer-template.json',
  }, {
    limit = math.huge,
    type = 'file',
    path = vim.fs.joinpath(vim.fn.stdpath('cache'), 'local-devcontainer.nvim', 'templates'),
  })

  return paths
end

---@class DevcontainerTemplate
---@field id string
---@field name string
---@field description string
---@field publisher string

---@param file_path string
---@return DevcontainerTemplate|nil
local function parse(file_path)
  local file = io.open(file_path, 'r')

  if not file then
    print('File not found: ' .. file_path)
    return nil
  end

  local content = file:read('*a')

  return vim.json.decode(content)
end

---@return DevcontainerTemplate[]
local function list_devcontainer_template()
  local tb = {}
  for _, v in ipairs(list_devcontainer_template_path()) do
    table.insert(tb, parse(v))
  end
  return tb
end

---@param callback fun(DevcontainerTemplate)
function M.select_devcontainer_template(callback)
  callback = callback or function() end
  vim.ui.select(list_devcontainer_template(), {
    prompt = 'select template',
    format_item = function(item)
      return item.id
    end,
  }, callback)
end

return M
