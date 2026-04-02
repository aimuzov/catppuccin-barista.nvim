# catppuccin-barista.nvim

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-%3E%3D0.8.0-green.svg)](https://neovim.io)

Create custom [catppuccin](https://github.com/catppuccin/nvim) flavours as first-class citizens.

> **Why "barista"?** Catppuccin uses coffee terminology — its themes are called _flavours_ (latte, frappe, macchiato, mocha). A _barista_ is someone who crafts coffee drinks. This plugin lets you craft your own flavours.

This plugin monkey-patches catppuccin/nvim to support custom flavours with full integration:

- `:colorscheme catppuccin-<your-flavour>`
- `:Catppuccin <your-flavour>` command
- `highlight_overrides` support
- Automatic compilation

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Screenshots](#screenshots)
- [Presets](#presets)
- [Beautifier (optional)](#beautifier-optional)
- [Utilities](#utilities)
- [API](#api)
- [How It Works](#how-it-works)
- [Development](#development)
- [License](#license)

## Requirements

- Neovim >= 0.8.0
- [catppuccin/nvim](https://github.com/catppuccin/nvim)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "catppuccin/nvim",
  name = "catppuccin",
  dependencies = { "aimuzov/catppuccin-barista.nvim" },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "catppuccin/nvim",
  as = "catppuccin",
  requires = { "aimuzov/catppuccin-barista.nvim" },
}
```

## Usage

### Using Presets

The easiest way to get started — use built-in presets:

```lua
require("catppuccin-barista").setup({
  presets = { "espresso" },
})

require("catppuccin").setup({
  flavour = "espresso",
})
```

Enable all available presets:

```lua
require("catppuccin-barista").setup({
  presets = true,
})

require("catppuccin").setup({
  flavour = "espresso",
})
```

### With lazy.nvim

```lua
{
  "catppuccin/nvim",
  name = "catppuccin",
  dependencies = { "aimuzov/catppuccin-barista.nvim" },
  opts = {
    flavour = "espresso",
  },
  config = function(_, opts)
    require("catppuccin-barista").setup({
      presets = { "espresso" },
    })
    require("catppuccin").setup(opts)
  end,
}
```

### Custom Flavours

Define your own flavours with all 26 required colors:

```lua
require("catppuccin-barista").setup({
  flavours = {
    my_theme = {
      palette = {
        rosewater = "#f5e0dc",
        flamingo  = "#f2cdcd",
        pink      = "#f5c2e7",
        mauve     = "#cba6f7",
        red       = "#f38ba8",
        maroon    = "#eba0ac",
        peach     = "#fab387",
        yellow    = "#f9e2af",
        green     = "#a6e3a1",
        teal      = "#94e2d5",
        sky       = "#89dceb",
        sapphire  = "#74c7ec",
        blue      = "#89b4fa",
        lavender  = "#b4befe",
        text      = "#cdd6f4",
        subtext1  = "#bac2de",
        subtext0  = "#a6adc8",
        overlay2  = "#9399b2",
        overlay1  = "#7f849c",
        overlay0  = "#6c7086",
        surface2  = "#585b70",
        surface1  = "#45475a",
        surface0  = "#313244",
        base      = "#1e1e2e",
        mantle    = "#181825",
        crust     = "#11111b",
      },
    },
  },
})

require("catppuccin").setup({
  flavour = "my_theme",
})
```

Shorthand without `flavours` key:

```lua
require("catppuccin-barista").setup({
  my_theme = {
    palette = { --[[ 26 colors ]] },
  },
})

require("catppuccin").setup({
  flavour = "my_theme",
})
```

### Presets + Custom Flavours

```lua
require("catppuccin-barista").setup({
  presets = { "espresso" },
  flavours = {
    my_light_theme = {
      palette = { --[[ ... ]] },
      opts = { background = "light" },
    },
  },
})

require("catppuccin").setup({
  flavour = "espresso",
})
```

### Manual Setup

For more control, use `register()` and `apply()` separately:

```lua
local barista = require("catppuccin-barista")

barista.register("my_theme", {
  rosewater = "#f5e0dc",
  -- ... all 26 colors
})

barista.register("my_light_theme", {
  -- ... all 26 colors
}, { background = "light" })

-- Apply patches BEFORE catppuccin.setup()
barista.apply()

require("catppuccin").setup({
  flavour = "my_theme",
})
```

## Screenshots

Preview of the built-in presets (screenshots are in the `assets/` directory):

| Flavour      | Preview                              |
| ------------ | ------------------------------------ |
| `espresso`   | ![espresso](assets/espresso.png)     |
| `darkroast`  | ![darkroast](assets/darkroast.png)   |
| `draculatte` | ![draculatte](assets/draculatte.png) |
| `gruvbrew`   | ![gruvbrew](assets/gruvbrew.png)     |
| `kanagato`   | ![kanagato](assets/kanagato.png)     |
| `nightbrew`  | ![nightbrew](assets/nightbrew.png)   |
| `nordiccino` | ![nordiccino](assets/nordiccino.png) |
| `rosetto`    | ![rosetto](assets/rosetto.png)       |
| `solarbica`  | ![solarbica](assets/solarbica.png)   |

## Presets

Available built-in presets:

| Name         | Based on    | Description                               |
| ------------ | ----------- | ----------------------------------------- |
| `darkroast`  | One Dark    | Atom One Dark theme                       |
| `draculatte` | Dracula     | Popular dark theme with vibrant colors    |
| `espresso`   | —           | Warm dark theme with muted tones          |
| `gruvbrew`   | Gruvbox     | Retro groove color scheme                 |
| `kanagato`   | Kanagawa    | Dark theme inspired by Katsushika Hokusai |
| `nightbrew`  | Tokyo Night | Clean dark theme inspired by Tokyo night  |
| `nordiccino` | Nord        | Arctic, north-bluish color palette        |
| `rosetto`    | Rosé Pine   | Soho vibes with a dark, muted aesthetic   |
| `solarbica`  | Solarized   | Precision colors for machines and people  |

## Beautifier (optional)

The `beautifier` module is a **lazy.nvim** plugin spec (not loaded by `require("catppuccin-barista")` automatically). It augments [catppuccin/nvim](https://github.com/catppuccin/nvim) with opinionated highlight overrides for many plugins (Neo-tree, Noice, Snacks, Git Signs, Diffview, Trouble, Blink completion, and others), plus integration specs for **bufferline.nvim** and **lualine.nvim** that refresh when the `catppuccin*` colorscheme changes.

Enable it by importing the module in your lazy spec (after this plugin is available on the runtime path):

```lua
require("lazy").setup({
  spec = {
    { "aimuzov/catppuccin-barista.nvim" },
    { import = "catppuccin-barista.beautifier" },
    -- ...
  },
})
```

Call `require("catppuccin-barista").setup(...)` and `require("catppuccin").setup(...)` as usual (see [Usage](#usage)). If you set `highlight_overrides` in catppuccin opts, those are **merged** with the beautifier’s overrides (`vim.tbl_deep_extend("force", ...)`), so your callbacks can extend or override the bundled groups.

Barista-registered flavours use each flavour’s `background` (`"dark"` / `"light"`) to pick the right tweak set where applicable.

## Utilities

`require("catppuccin-barista.util").color_blend(color_first, color_second, percentage)` blends two `#RRGGBB` strings. `percentage` is the weight of `color_second` (0–100). Used internally by the beautifier; you may reuse it for custom highlights or tooling.

## API

### `barista.setup(config)`

Main setup function. Combines register + apply. Call **before** `catppuccin.setup()`.

| Parameter         | Type                              | Description                               |
| ----------------- | --------------------------------- | ----------------------------------------- |
| `config.presets`  | `string[]\|boolean`               | Preset names to enable, or `true` for all |
| `config.flavours` | `table<string, {palette, opts?}>` | Custom flavour definitions                |

### `barista.get_flavours()`

Returns all registered flavours.

```lua
local flavours = require("catppuccin-barista").get_flavours()
-- Returns: { espresso = { palette = {...}, background = "dark" }, ... }
```

### `barista.get_presets()`

Returns a list of available preset names.

```lua
local presets = require("catppuccin-barista").get_presets()
-- Returns: { "darkroast", "draculatte", "espresso", "gruvbrew",
--            "kanagato", "nightbrew", "nordiccino", "rosetto", "solarbica" }
```

### `barista.register(name, palette, opts?)`

Register a custom flavour manually.

| Parameter         | Type              | Description                         |
| ----------------- | ----------------- | ----------------------------------- |
| `name`            | `string`          | Flavour name (e.g., `"espresso"`)   |
| `palette`         | `table`           | All 26 catppuccin palette colors    |
| `opts.background` | `"dark"\|"light"` | Background type (default: `"dark"`) |

Returns `boolean` — `true` if registration succeeded.

### `barista.unregister(name)`

Remove a previously registered flavour.

| Parameter | Type     | Description            |
| --------- | -------- | ---------------------- |
| `name`    | `string` | Flavour name to remove |

Returns `boolean` — `true` if removal succeeded.

### `barista.apply()`

Apply all registered flavours by patching catppuccin internals.
Call this **after** `register()` and **before** `catppuccin.setup()`.

Returns `boolean` — `true` if patching succeeded.

## Required Palette Keys

Your palette must include all 26 standard catppuccin colors:

```
rosewater, flamingo, pink, mauve, red, maroon, peach, yellow,
green, teal, sky, sapphire, blue, lavender, text, subtext1,
subtext0, overlay2, overlay1, overlay0, surface2, surface1,
surface0, base, mantle, crust
```

## How It Works

This plugin patches catppuccin in several ways:

1. **Module injection**: Injects your palette into `package.loaded["catppuccin.palettes.<name>"]`
2. **Flavour registration**: Adds your flavour to `catppuccin.flavours` table
3. **Colorscheme files**: Creates `colors/catppuccin-<name>.lua` in a cache directory
4. **Palette wrapper**: Wraps `get_palette()` to ensure palettes stay available

## Development

### Running Tests

```bash
make test
```

Requires [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (auto-installed on first run).

### Linting

```bash
make lint
```

Requires [luacheck](https://github.com/mpeterv/luacheck).

## License

MIT
