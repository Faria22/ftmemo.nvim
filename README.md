# ftmemo.nvim

A Neovim plugin that persistently remembers when you manually set the filetype for a specific file (e.g., via `:set filetype=rust`), and automatically restores that filetype the next time the same file is opened.

## Features

- **Automatic Detection**: Detects when you manually change a file's filetype
- **Persistent Storage**: Remembers filetype settings across Neovim sessions
- **Smart Restoration**: Automatically applies saved filetypes when opening files
- **Manual Management**: Commands to view and clear saved filetype mappings

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'Faria22/ftmemo.nvim',
  config = function()
    require('ftmemo').setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'Faria22/ftmemo.nvim',
  config = function()
    require('ftmemo').setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'Faria22/ftmemo.nvim'
```

Then add to your Neovim configuration:

```lua
require('ftmemo').setup()
```

## Usage

The plugin works automatically once installed. When you manually set a filetype for a file:

```vim
:set filetype=rust
```

The plugin will remember this setting and automatically apply it the next time you open the same file.

## Configuration

The plugin can be configured by passing options to the `setup()` function:

```lua
require('ftmemo').setup({
  enabled = true,                                    -- Enable/disable the plugin
  storage_file = vim.fn.stdpath('data') .. '/ftmemo.json', -- Where to store filetype mappings
  debug = false,                                     -- Enable debug logging
})
```

## Commands

- `:FtMemoShow` - Display all saved filetype mappings
- `:FtMemoClear` - Clear the saved filetype for the current file and clear the current buffer's filetype
- `:FtMemoCleanup` - Clean up saved mappings for files that no longer exist

## How it Works

1. **Detection**: The plugin monitors filetype changes using Neovim's autocommands
2. **Storage**: When a manual filetype change is detected, it's saved to a JSON file in your Neovim data directory
3. **Restoration**: When opening a file, the plugin checks if there's a saved filetype and applies it
4. **Persistence**: All mappings are stored persistently and survive Neovim restarts
5. **Cleanup**: Invalid mappings for non-existent files are automatically cleaned up on startup

## Examples

```bash
# Open a file without extension
nvim myfile

# Manually set the filetype
:set filetype=python

# Close and reopen the file
:q
nvim myfile
# The filetype will automatically be set to 'python'
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
