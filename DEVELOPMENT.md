# ftmemo.nvim - Developer Documentation

## Architecture

The plugin consists of several key components:

### Core Module (`lua/ftmemo/init.lua`)

The main module handles:

1. **Configuration Management**: Uses `vim.tbl_deep_extend` for merging user config with defaults
2. **Storage**: JSON-based persistence using `vim.json.encode/decode`
3. **Event Handling**: Autocommands for detecting and responding to filetype changes
4. **State Management**: Tracks manual vs automatic filetype changes

### Plugin Entry Point (`plugin/ftmemo.lua`)

Simple entry point that:
- Prevents double-loading with `vim.g.loaded_ftmemo`
- Calls `setup()` with default configuration

## Key Functions

### Detection Logic

The plugin uses a combination of approaches to detect manual filetype changes:

1. **FileType autocmd**: Triggers on any filetype change
2. **OptionSet autocmd**: Triggers specifically on filetype option changes
3. **State tracking**: Compares current filetype with previously known values

### Storage Format

Mappings are stored as JSON in the format:
```json
{
  "/absolute/path/to/file1": "rust",
  "/absolute/path/to/file2": "python"
}
```

### Timing Considerations

- **Restoration**: Uses `vim.defer_fn(fn, 10)` to allow Neovim's automatic filetype detection to run first
- **Manual detection**: Uses `vim.defer_fn(fn, 1)` for OptionSet events to ensure the option is fully set

## Error Handling

- **Corrupted storage**: Creates backup file and starts fresh
- **Missing directories**: Automatically creates data directory if needed
- **File not found**: Gracefully handles missing storage file
- **Invalid paths**: Validates file existence before processing

## Performance Considerations

- **Lazy loading**: Prevents recursive calls during restoration with `is_loading` flag
- **Cleanup**: Automatically removes mappings for non-existent files
- **Minimal overhead**: Only processes files with actual names (non-empty buffer names)

## Extension Points

The module returns a table with public functions:
- `setup(opts)`: Initialize the plugin
- `clear_filetype(filepath)`: Remove saved filetype for a file
- `show_mappings()`: Display all saved mappings

## Testing

Due to the Neovim-specific nature of the plugin, testing requires:
- Neovim runtime environment
- File system access for storage testing
- Buffer and autocmd functionality

## Dependencies

- Neovim 0.5+ (for Lua support)
- `vim.json` (available in Neovim 0.7+)
- Standard Neovim API functions