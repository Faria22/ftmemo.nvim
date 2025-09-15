# ftmemo.nvim - GitHub Copilot Instructions

ftmemo.nvim is a Neovim plugin that persistently remembers when you manually set the filetype for a specific file and automatically restores that filetype when the file is reopened.

**Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Working Effectively

### Initial Setup and Dependencies
- Install Neovim 0.5+ (Lua support required, Neovim 0.7+ recommended for vim.json): `sudo apt install -y neovim`
- Install Lua for syntax validation: `sudo apt install -y lua5.4`
- Install luacheck for linting: `sudo apt install -y luarocks && sudo luarocks install luacheck`
- No build process required - this is a pure Lua plugin with no compilation step
- Plugin loads in <50ms - **NEVER** set timeouts below 2 minutes for safety

### Testing the Plugin
- Create test environment: `NVIM_APPNAME=ftmemo-test`
- Load plugin in clean Neovim: `nvim --clean -u NONE -c "set rtp+=." -c "lua require('ftmemo').setup({debug=true})"`
- Test file creation: `echo "print('test')" > test_file.txt`
- Manual filetype test: Open file, run `:set filetype=python`, save and reopen to verify restoration
- **Expected timing**: Plugin initialization <10ms, filetype operations <5ms

### Validation Scenarios
**CRITICAL**: Always test these complete scenarios after making changes:

1. **Basic Functionality Test**:
   - Create a file without extension: `touch testfile`
   - Open in Neovim with ftmemo loaded
   - **IMPORTANT**: Wait for initial loading (use `sleep 50m` command)
   - Manually set filetype: `:set filetype=python`
   - Save and close file
   - Reopen file - verify filetype is automatically restored to python

2. **Command Testing**:
   - `:FtMemoShow` - should display saved mappings
   - `:FtMemoClear` - should clear current file's saved filetype
   - `:FtMemoCleanup` - should remove mappings for non-existent files

3. **Storage Persistence**:
   - Verify JSON storage file created in `~/.local/share/nvim-*/ftmemo.json`
   - Check file contains correct absolute path mappings
   - Confirm mappings survive Neovim restarts

### Linting and Code Quality
- Run luacheck: `luacheck lua/ftmemo/init.lua --ignore 113 --globals vim`
- **Expected**: Only whitespace warnings (621-631), no syntax or logic errors
- **Timing**: Linting completes in <100ms
- All Lua files must be syntactically valid for Neovim's Lua runtime

## Repository Structure

### Key Files
```
├── lua/ftmemo/init.lua       # Main plugin logic (283 lines)
├── plugin/ftmemo.lua         # Plugin entry point (9 lines)
├── README.md                 # User documentation
├── DEVELOPMENT.md            # Developer documentation
└── .gitignore               # Excludes test files and storage files
```

### Core Architecture
- **lua/ftmemo/init.lua**: Contains all plugin logic, configuration, storage, and commands
- **plugin/ftmemo.lua**: Simple entry point that prevents double-loading and calls setup()
- **Storage**: JSON file in Neovim's stdpath('data') directory
- **No external dependencies**: Pure Neovim Lua API only

## Plugin Functionality

### Detection Logic
- Uses `FileType` and `OptionSet` autocommands to detect manual filetype changes
- Compares current filetype against tracked values to identify manual changes
- Implements `is_loading` flag to prevent recursive restoration loops
- **Timing**: Uses `vim.defer_fn(fn, 10)` for restoration, `vim.defer_fn(fn, 1)` for detection

### Storage Format
```json
{
  "/absolute/path/to/file1": "rust",
  "/absolute/path/to/file2": "python"
}
```

### Configuration Options
```lua
require('ftmemo').setup({
  enabled = true,                                    -- Enable/disable plugin
  storage_file = vim.fn.stdpath('data') .. '/ftmemo.json', -- Storage location
  debug = false,                                     -- Debug logging
})
```

## Common Development Tasks

### Adding New Features
- Modify `lua/ftmemo/init.lua` - all logic is contained here
- Add new commands using `vim.api.nvim_create_user_command`
- Always test with debug mode enabled: `setup({debug=true})`
- Verify storage file integrity after changes

### Debugging Issues
- Enable debug logging: `require('ftmemo').setup({debug=true})`
- Check storage file: `cat ~/.local/share/nvim-*/ftmemo.json`
- Test with minimal config: `nvim --clean -u NONE -c "set rtp+=." -c "lua require('ftmemo').setup({debug=true})"`
- Verify autocommands: `:au FtMemo` in Neovim

### Error Handling
- Plugin gracefully handles corrupted storage (creates backup)
- Missing directories are created automatically
- Invalid file paths are filtered out during cleanup
- All file operations include error checking with fallback behavior

## Performance Considerations
- Plugin uses lazy loading with flags to prevent recursive calls
- Automatic cleanup removes mappings for non-existent files
- Minimal overhead: only processes files with valid buffer names
- Storage operations are atomic with error recovery

## Testing Without Build System
- No traditional build/test framework - use manual validation
- Create test files in `/tmp` to avoid committing test artifacts
- Use different `NVIM_APPNAME` for isolated testing: `NVIM_APPNAME=ftmemo-test`
- Always test complete user workflows, not just individual functions

## Timing Expectations
- **Plugin initialization**: <10ms
- **Filetype restoration**: <5ms  
- **Storage operations**: <20ms
- **Luacheck linting**: <100ms
- **Manual validation scenario**: <30 seconds per test

**NEVER CANCEL**: While this plugin has no long-running builds, always allow adequate time for Neovim startup and file operations. Set minimum timeouts of 30 seconds for any automated testing.

## File Locations Reference
- **Plugin source**: `lua/ftmemo/init.lua` and `plugin/ftmemo.lua`
- **User docs**: `README.md`
- **Developer docs**: `DEVELOPMENT.md`  
- **Storage file**: `~/.local/share/nvim-*/ftmemo.json` (varies by NVIM_APPNAME)
- **Test files**: Create in `/tmp` or use `test_*` prefix (gitignored)

## Quick Commands Reference
```bash
# Test plugin functionality (CRITICAL: include sleep delay for proper detection)
NVIM_APPNAME=ftmemo-test nvim --clean -u NONE -c "set rtp+=." -c "lua require('ftmemo').setup({debug=true})" -c "e testfile" -c "sleep 50m" -c "set filetype=python" -c "w" -c "q"

# Check storage
cat ~/.local/share/nvim-ftmemo-test/ftmemo.json

# Lint code  
luacheck lua/ftmemo/init.lua --ignore 113 --globals vim

# Verify restoration
NVIM_APPNAME=ftmemo-test nvim --clean -u NONE -c "set rtp+=." -c "lua require('ftmemo').setup({debug=true})" -c "e testfile" -c "sleep 50m" -c "echo &filetype" -c "q"
```