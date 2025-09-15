local M = {}

-- Default configuration
local config = {
  enabled = true,
  storage_file = vim.fn.stdpath('data') .. '/ftmemo.json',
  debug = false,
}

-- Internal state
local filetype_map = {}
local is_loading = false
local last_manual_filetype = {}

-- Helper function for debug logging
local function log(msg)
  if config.debug then
    print('[ftmemo] ' .. msg)
  end
end

-- Load filetype mappings from storage
local function load_mappings()
  local file = io.open(config.storage_file, 'r')
  if not file then
    log('No existing storage file found, starting fresh')
    return
  end
  
  local content = file:read('*all')
  file:close()
  
  if content and content ~= '' then
    local ok, data = pcall(vim.json.decode, content)
    if ok and type(data) == 'table' then
      filetype_map = data
      log('Loaded ' .. vim.tbl_count(filetype_map) .. ' filetype mappings')
    else
      log('Failed to parse storage file, starting fresh')
      -- Backup the corrupted file
      local backup_file = config.storage_file .. '.backup'
      local backup = io.open(backup_file, 'w')
      if backup then
        backup:write(content)
        backup:close()
        log('Backed up corrupted storage file to: ' .. backup_file)
      end
    end
  end
end

-- Save filetype mappings to storage
local function save_mappings()
  local file = io.open(config.storage_file, 'w')
  if not file then
    vim.notify('[ftmemo] Failed to open storage file for writing: ' .. config.storage_file, vim.log.levels.ERROR)
    return
  end
  
  local ok, content = pcall(vim.json.encode, filetype_map)
  if ok then
    file:write(content)
    file:close()
    log('Saved ' .. vim.tbl_count(filetype_map) .. ' filetype mappings')
  else
    file:close()
    vim.notify('[ftmemo] Failed to encode filetype mappings', vim.log.levels.ERROR)
  end
end

-- Get the absolute path of a file
local function get_file_path(bufnr)
  bufnr = bufnr or 0
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    return nil
  end
  
  -- Convert to absolute path and normalize
  local abs_path = vim.fn.resolve(vim.fn.expand(path))
  
  -- Ensure the path exists (for cleaning up old mappings)
  if vim.fn.filereadable(abs_path) == 0 and vim.fn.isdirectory(abs_path) == 0 then
    return nil
  end
  
  return abs_path
end

-- Clean up mappings for files that no longer exist
local function cleanup_mappings()
  local cleaned = false
  for filepath, _ in pairs(filetype_map) do
    if vim.fn.filereadable(filepath) == 0 and vim.fn.isdirectory(filepath) == 0 then
      filetype_map[filepath] = nil
      last_manual_filetype[filepath] = nil
      cleaned = true
      log('Cleaned up mapping for non-existent file: ' .. filepath)
    end
  end
  
  if cleaned then
    save_mappings()
  end
end

-- Check if filetype was set manually by comparing with automatic detection
local function was_filetype_set_manually(bufnr)
  bufnr = bufnr or 0
  local current_ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  local filepath = get_file_path(bufnr)
  
  if not filepath or current_ft == '' then
    return false
  end
  
  -- Store the current filetype to check against later
  if not last_manual_filetype[filepath] then
    last_manual_filetype[filepath] = current_ft
    return false
  end
  
  -- If filetype changed from what we remembered, it was likely manual
  if last_manual_filetype[filepath] ~= current_ft then
    -- Additional check: make sure we're not in the middle of restoration
    if not is_loading then
      log('Manual filetype change detected: ' .. filepath .. ' -> ' .. current_ft)
      return true
    end
  end
  
  return false
end

-- Handle filetype change events
local function on_filetype_changed()
  if is_loading then
    return
  end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = get_file_path(bufnr)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  
  if not filepath or filetype == '' then
    return
  end
  
  -- Check if this appears to be a manual change
  if was_filetype_set_manually(bufnr) then
    filetype_map[filepath] = filetype
    save_mappings()
    log('Saved manual filetype: ' .. filepath .. ' -> ' .. filetype)
  end
  
  -- Update our tracking
  last_manual_filetype[filepath] = filetype
end

-- Restore filetype for a buffer
local function restore_filetype(bufnr)
  bufnr = bufnr or 0
  local filepath = get_file_path(bufnr)
  
  if not filepath then
    return
  end
  
  local saved_filetype = filetype_map[filepath]
  if saved_filetype then
    is_loading = true
    vim.api.nvim_buf_set_option(bufnr, 'filetype', saved_filetype)
    last_manual_filetype[filepath] = saved_filetype
    is_loading = false
    log('Restored filetype: ' .. filepath .. ' -> ' .. saved_filetype)
  else
    -- Track the auto-detected filetype
    local auto_filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
    last_manual_filetype[filepath] = auto_filetype
  end
end

-- Clear saved filetype for a file
function M.clear_filetype(filepath)
  local bufnr = vim.api.nvim_get_current_buf()
  if not filepath then
    filepath = get_file_path(bufnr)
  end
  
  if filepath and filetype_map[filepath] then
    filetype_map[filepath] = nil
    last_manual_filetype[filepath] = nil
    save_mappings()
    log('Cleared saved filetype for: ' .. filepath)
    vim.notify('[ftmemo] Cleared saved filetype for: ' .. vim.fn.fnamemodify(filepath, ':t'))
  else
    vim.notify('[ftmemo] No saved filetype found for current file')
  end
  
  -- Clear the current buffer's filetype as requested in the issue
  vim.api.nvim_buf_set_option(bufnr, 'filetype', '')
  log('Cleared current buffer filetype')
end

-- Show saved filetypes
function M.show_mappings()
  if vim.tbl_isempty(filetype_map) then
    vim.notify('[ftmemo] No saved filetype mappings')
    return
  end
  
  local lines = {'Saved filetype mappings:'}
  for filepath, filetype in pairs(filetype_map) do
    table.insert(lines, '  ' .. vim.fn.fnamemodify(filepath, ':~') .. ' -> ' .. filetype)
  end
  
  vim.notify(table.concat(lines, '\n'))
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend('force', config, opts)
  
  if not config.enabled then
    return
  end
  
  -- Create the data directory if it doesn't exist
  local data_dir = vim.fn.fnamemodify(config.storage_file, ':h')
  if vim.fn.isdirectory(data_dir) == 0 then
    vim.fn.mkdir(data_dir, 'p')
  end
  
  -- Load existing mappings
  load_mappings()
  
  -- Clean up old mappings on startup
  cleanup_mappings()
  
  -- Create autocommands
  local group = vim.api.nvim_create_augroup('FtMemo', { clear = true })
  
  -- Restore filetype when opening files
  vim.api.nvim_create_autocmd({'BufReadPost', 'BufNewFile'}, {
    group = group,
    callback = function()
      -- Use a timer to let Neovim's filetype detection run first
      vim.defer_fn(function()
        restore_filetype()
      end, 10)
    end,
  })
  
  -- Track filetype changes (potential manual settings)
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = on_filetype_changed,
  })
  
  -- Also track option changes for more immediate detection
  vim.api.nvim_create_autocmd('OptionSet', {
    group = group,
    pattern = 'filetype',
    callback = function()
      -- Small delay to ensure the option is fully set
      vim.defer_fn(on_filetype_changed, 1)
    end,
  })
  
  log('ftmemo.nvim initialized')
end

-- Commands
vim.api.nvim_create_user_command('FtMemoClear', function()
  M.clear_filetype()
end, { desc = 'Clear saved filetype for current file' })

vim.api.nvim_create_user_command('FtMemoShow', function()
  M.show_mappings()
end, { desc = 'Show all saved filetype mappings' })

vim.api.nvim_create_user_command('FtMemoCleanup', function()
  cleanup_mappings()
  vim.notify('[ftmemo] Cleaned up mappings for non-existent files')
end, { desc = 'Clean up saved mappings for files that no longer exist' })

return M