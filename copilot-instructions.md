# GitHub Copilot Instructions for ftmemo.nvim

This file provides guidelines for GitHub Copilot when working on the ftmemo.nvim project - a Neovim plugin that remembers manually set filetypes across sessions.

## Project Overview

ftmemo.nvim is a Lua-based Neovim plugin that:
- Detects when users manually change file types (e.g., `:set filetype=rust`)
- Persistently stores these preferences in JSON format
- Automatically restores saved filetypes when files are reopened
- Provides commands for managing saved filetype mappings

## Code Standards and Architecture

### Lua Best Practices
- Follow modern Lua 5.1+ conventions (Neovim's embedded Lua version)
- Use `local` variables whenever possible to avoid global namespace pollution
- Prefer table-based modules with explicit return statements
- Use meaningful variable names that reflect Neovim conventions (e.g., `bufnr`, `filepath`)
- Follow the existing code style: 2-space indentation, snake_case for functions and variables

### Neovim API Guidelines
- Use `vim.api.*` functions for low-level operations (buffers, windows, autocommands)
- Use `vim.fn.*` for Vimscript function access when needed
- Prefer `vim.notify()` over `print()` for user-facing messages
- Use `vim.log.levels.*` for appropriate message severity
- Use autocommand groups (`vim.api.nvim_create_augroup`) for proper cleanup
- Leverage `vim.defer_fn()` for timing-sensitive operations

### Plugin Architecture
- Keep the main module (`lua/ftmemo/init.lua`) focused on core functionality
- Use the plugin entry point (`plugin/ftmemo.lua`) only for initialization
- Maintain clear separation between:
  - Configuration management
  - Storage operations (JSON persistence)
  - Event handling (autocommands)
  - User commands
  - Internal state tracking

### Error Handling and Robustness
- Always use `pcall()` for operations that might fail (JSON parsing, file I/O)
- Create backup files for corrupted data before attempting recovery
- Validate file paths and existence before processing
- Handle edge cases gracefully (empty buffers, unnamed files, missing directories)
- Provide meaningful error messages to users via `vim.notify()`

### Performance Considerations
- Use flags like `is_loading` to prevent recursive operations
- Clean up obsolete mappings automatically on startup
- Minimize file I/O operations by batching saves
- Use `vim.defer_fn()` strategically to avoid interfering with Neovim's startup sequence
- Only process buffers with actual filenames (avoid empty buffer names)

## Security and Data Integrity

### File Operations
- Always validate file paths before reading/writing
- Use `vim.fn.resolve()` and `vim.fn.expand()` for path normalization  
- Create necessary directories with proper permissions (`vim.fn.mkdir(data_dir, 'p')`)
- Never execute user-provided strings as code
- Sanitize data before JSON encoding/decoding

### Storage Format
- Use structured JSON for persistent storage with proper validation
- Store absolute file paths to ensure consistency across working directories
- Include format versioning for future compatibility
- Validate JSON structure after loading and provide recovery mechanisms

## Testing and Quality Assurance

### Manual Testing Approaches
- Test filetype detection accuracy with various file types
- Verify persistence across Neovim sessions
- Test edge cases: files without extensions, symlinks, non-existent files
- Validate command functionality (`:FtMemoShow`, `:FtMemoClear`, `:FtMemoCleanup`)
- Ensure proper cleanup of autocommands and state

### Configuration Testing
- Test with different storage file locations
- Verify behavior with disabled plugin state
- Test debug logging functionality
- Validate configuration merging with user options

## Code Patterns to Follow

### Autocommand Management
```lua
-- Create grouped autocommands for proper cleanup
local group = vim.api.nvim_create_augroup('FtMemo', { clear = true })
vim.api.nvim_create_autocmd({'BufReadPost', 'BufNewFile'}, {
  group = group,
  callback = function()
    -- Implementation
  end,
})
```

### Safe File Operations
```lua
-- Always use pcall for file operations
local ok, content = pcall(vim.json.decode, file_content)
if not ok then
  -- Handle error gracefully with user notification
  vim.notify('[ftmemo] Error parsing storage file', vim.log.levels.ERROR)
  return
end
```

### Configuration Handling
```lua
-- Use vim.tbl_deep_extend for merging user config
config = vim.tbl_deep_extend('force', default_config, user_opts or {})
```

## Code Patterns to Avoid

### Performance Anti-patterns
- Don't create autocommands without groups (prevents proper cleanup)
- Avoid synchronous file I/O in frequently called functions
- Don't use global variables for plugin state
- Avoid redundant file existence checks

### API Misuse
- Don't use deprecated `vim.api.nvim_buf_get_option()` (prefer `vim.bo` when available)
- Avoid direct buffer manipulation without checking buffer validity
- Don't create user commands multiple times (check if already exists)
- Avoid using `vim.cmd()` when direct API functions are available

### Error Handling Issues
- Don't silently ignore errors in critical operations
- Avoid exposing internal state in error messages
- Don't continue operations after detecting corrupted data without user notification

## Documentation Standards

- Maintain clear function docstrings for public API functions
- Use descriptive comments for complex logic (timing, state management)
- Keep README.md synchronized with actual functionality
- Document configuration options with examples and default values
- Include usage examples for all user-facing commands

## Module Structure

When extending the plugin, maintain this structure:
```
lua/ftmemo/
├── init.lua          # Main module with core functionality
└── [future modules]  # Additional modules for specific features

plugin/
└── ftmemo.lua        # Plugin entry point and command definitions
```

## Debugging and Development

- Use the `debug` configuration option for verbose logging
- Include file paths and operation context in debug messages
- Log state transitions and important decision points
- Provide clear markers for plugin initialization and cleanup
- Use consistent prefixes in log messages: `[ftmemo]`

## Integration Guidelines

- Ensure compatibility with popular Neovim plugin managers (lazy.nvim, packer, vim-plug)
- Don't interfere with other filetype detection plugins
- Respect existing filetype settings when appropriate
- Provide clear setup documentation for different installation methods
- Consider backward compatibility when making API changes