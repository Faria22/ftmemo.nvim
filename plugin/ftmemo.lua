-- ftmemo.nvim - Remembers manually set filetypes per file across sessions
-- Entry point for the plugin

if vim.g.loaded_ftmemo then
  return
end
vim.g.loaded_ftmemo = 1

-- Default setup with basic configuration
require('ftmemo').setup()