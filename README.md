# Vendure Docs Browser

Browse the [Vendure](https://docs.vendure.io/) documentation directly from Neovim using Telescope.

The plugin automatically detects Vendure projects and fetches the docs index from [docs.vendure.io/llms.txt](https://docs.vendure.io/llms.txt) in the background. Use the `:BrowseVendureDocs` command to fuzzy-find any doc page and open it in your browser.

Inspired by [bieglers-vendure-plugins/vscode-extension-vendure-helper](https://github.com/DanielBiegler/bieglers-vendure-plugins/tree/master/packages/vscode-extension-vendure-helper).

## Requirements

- **curl** — used to fetch the docs index
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) — fuzzy finder UI

### Optional

- [fidget.nvim](https://github.com/j-hui/fidget.nvim) — shows a loading spinner while fetching the docs index

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  'kwerie/vendure-nvim-docs-plugin',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    -- 'j-hui/fidget.nvim', -- optional for fancy loading messages
  },
  config = function()
    require('vendure-nvim-docs-plugin').setup({})
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'kwerie/vendure-nvim-docs-plugin',
  requires = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('vendure-nvim-docs-plugin').setup({})
  end,
}
```

## Keybinding

The plugin exposes a `:BrowseVendureDocs` command. Bind it to a key of your choice:

```lua
vim.api.nvim_set_keymap('n', '<leader>vd', ':BrowseVendureDocs<CR>', { noremap = true, silent = true })
```

Full lazy.nvim example with keybinding:

```lua
return {
  'kwerie/vendure-nvim-docs-plugin',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    local vendure_docs_plugin = require('vendure-nvim-docs-plugin')

    vendure_docs_plugin.setup({})

    vim.api.nvim_set_keymap('n', '<leader>vd', ':BrowseVendureDocs<CR>', { noremap = true, silent = true })
  end,
}
```
