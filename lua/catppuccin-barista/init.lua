---@mod catppuccin-barista Catppuccin Barista
---@brief [[
--- A plugin for creating custom catppuccin flavours as first-class citizens.
---
--- Monkey-patches catppuccin/nvim to support custom flavours with full
--- integration: :colorscheme, :Catppuccin command, highlight_overrides, etc.
---
--- How catppuccin works internally:
---   1. :colorscheme catppuccin-<X>  ->  loads colors/catppuccin-<X>.lua
---   2. That file calls              ->  require("catppuccin").load("<X>")
---   3. load() validates <X> via     ->  M.flavours table
---   4. load() reads compiled cache  ->  compile_path/<X>  (binary bytecode)
---   5. If no cache, calls           ->  M.compile()
---   6. compile() iterates           ->  M.flavours and for each:
---        mapper.apply(flvr) -> palettes.get_palette(flvr) -> require("catppuccin.palettes.<flvr>")
---        then generates nvim_set_hl calls and dumps bytecode to compile_path/<flvr>
---
--- This plugin patches:
---   a) Inject palette into package.loaded["catppuccin.palettes.<name>"]
---   b) Add name to catppuccin.flavours table (validation + compile iteration)
---   c) Create colors/catppuccin-<name>.lua in runtimepath (for :colorscheme)
---   d) Wrap get_palette to ensure palette is always available
---@brief ]]

local REQUIRED_KEYS = {
	"rosewater",
	"flamingo",
	"pink",
	"mauve",
	"red",
	"maroon",
	"peach",
	"yellow",
	"green",
	"teal",
	"sky",
	"sapphire",
	"blue",
	"lavender",
	"text",
	"subtext1",
	"subtext0",
	"overlay2",
	"overlay1",
	"overlay0",
	"surface2",
	"surface1",
	"surface0",
	"base",
	"mantle",
	"crust",
}

---@class CatppuccinBarista
---@field _flavours table<string, CatppuccinBaristaFlavour>
local M = {}
M._flavours = {}

---@class CatppuccinBaristaFlavour
---@field palette CatppuccinPalette
---@field background "dark"|"light"

---@class CatppuccinPalette
---@field rosewater string
---@field flamingo string
---@field pink string
---@field mauve string
---@field red string
---@field maroon string
---@field peach string
---@field yellow string
---@field green string
---@field teal string
---@field sky string
---@field sapphire string
---@field blue string
---@field lavender string
---@field text string
---@field subtext1 string
---@field subtext0 string
---@field overlay2 string
---@field overlay1 string
---@field overlay0 string
---@field surface2 string
---@field surface1 string
---@field surface0 string
---@field base string
---@field mantle string
---@field crust string

---@class CatppuccinBaristaRegisterOpts
---@field background? "dark"|"light" Background type (default: "dark")

--- Register a custom flavour.
---@param name string Flavour name, e.g. "espresso"
---@param palette CatppuccinPalette All 26 catppuccin palette colors
---@param opts? CatppuccinBaristaRegisterOpts Options
---@return boolean success
function M.register(name, palette, opts)
	opts = opts or {}

	-- Validate name
	if type(name) ~= "string" or name == "" then
		vim.notify("[catppuccin-barista] flavour name must be a non-empty string", vim.log.levels.ERROR)
		return false
	end

	if name:match("[^%w_-]") then
		vim.notify(
			("[catppuccin-barista] flavour name '%s' contains invalid characters (use only a-z, 0-9, _, -)"):format(
				name
			),
			vim.log.levels.ERROR
		)
		return false
	end

	-- Warn about built-in flavours
	local builtins = { latte = true, frappe = true, macchiato = true, mocha = true }
	if builtins[name] then
		vim.notify(
			("[catppuccin-barista] '%s' is a built-in catppuccin flavour and will be overridden"):format(name),
			vim.log.levels.WARN
		)
	end

	-- Validate palette keys
	local missing_keys = {}
	for _, key in ipairs(REQUIRED_KEYS) do
		if not palette[key] then
			table.insert(missing_keys, key)
		end
	end

	if #missing_keys > 0 then
		vim.notify(
			("[catppuccin-barista] palette '%s' is missing keys: %s"):format(name, table.concat(missing_keys, ", ")),
			vim.log.levels.ERROR
		)
		return false
	end

	M._flavours[name] = {
		palette = vim.deepcopy(palette),
		background = opts.background or "dark",
	}

	return true
end

--- Get all registered flavours.
---@return table<string, CatppuccinBaristaFlavour>
function M.get_flavours()
	return M._flavours
end

--- Unregister a previously registered flavour.
--- Note: This only removes from internal registry. To fully clean up,
--- you may need to restart Neovim or manually clear package.loaded.
---@param name string Flavour name to unregister
---@return boolean success
function M.unregister(name)
	if not M._flavours[name] then
		vim.notify(("[catppuccin-barista] flavour '%s' is not registered"):format(name), vim.log.levels.WARN)
		return false
	end

	M._flavours[name] = nil
	package.loaded["catppuccin.palettes." .. name] = nil

	-- Remove from catppuccin.flavours if possible
	local ok, catppuccin = pcall(require, "catppuccin")
	if ok and catppuccin.flavours then
		catppuccin.flavours[name] = nil
	end

	-- Remove colorscheme file
	local lua_file = vim.fn.stdpath("cache") .. "/catppuccin-barista/colors/catppuccin-" .. name .. ".lua"
	os.remove(lua_file)

	return true
end

--- Apply all registered flavours by patching catppuccin internals.
--- Call this AFTER register() and BEFORE catppuccin.setup().
---@return boolean success
function M.apply()
	if vim.tbl_isempty(M._flavours) then
		return true
	end

	local ok, catppuccin = pcall(require, "catppuccin")
	if not ok then
		vim.notify("[catppuccin-barista] catppuccin.nvim is required but not found", vim.log.levels.ERROR)
		return false
	end

	-- (a) Inject palettes into the module system
	for name, def in pairs(M._flavours) do
		package.loaded["catppuccin.palettes." .. name] = def.palette
	end

	-- (b) Add to catppuccin.flavours table
	local max_idx = 0
	for _, idx in pairs(catppuccin.flavours) do
		if idx > max_idx then
			max_idx = idx
		end
	end
	for name, _ in pairs(M._flavours) do
		if not catppuccin.flavours[name] then
			max_idx = max_idx + 1
			catppuccin.flavours[name] = max_idx
		end
	end

	-- (c) Create colors/catppuccin-<name>.lua files
	--     in a temp runtimepath directory so that
	--     :colorscheme catppuccin-<name> resolves
	local colors_dir = vim.fn.stdpath("cache") .. "/catppuccin-barista/colors"
	vim.fn.mkdir(colors_dir, "p")

	-- Clean up stale colorscheme files (.lua and legacy .vim)
	for _, ext in ipairs({ "lua", "vim" }) do
		local existing_files = vim.fn.glob(colors_dir .. "/catppuccin-*." .. ext, false, true)
		for _, file in ipairs(existing_files) do
			local flavour_name = file:match("catppuccin%-(.+)%." .. ext .. "$")
			if flavour_name and (ext == "vim" or not M._flavours[flavour_name]) then
				os.remove(file)
			end
		end
	end

	for name, def in pairs(M._flavours) do
		local lua_file = colors_dir .. "/catppuccin-" .. name .. ".lua"

		-- Set vim.o.background based on flavour definition
		local bg_cmd = ("vim.o.background = '%s'"):format(def.background)
		local load_cmd = ('require("catppuccin").load("%s")'):format(name)
		local content = ("%s\n%s\n"):format(bg_cmd, load_cmd)

		-- Only write if missing or changed
		local f = io.open(lua_file, "r")
		local existing = f and f:read("*a") or nil
		if f then
			f:close()
		end

		if existing ~= content then
			f = io.open(lua_file, "w")
			if not f then
				vim.notify(("[catppuccin-barista] failed to write %s"):format(lua_file), vim.log.levels.WARN)
			else
				f:write(content)
				f:close()
			end
		end
	end

	-- Add to runtimepath (idempotent)
	local barista_rtp = vim.fn.stdpath("cache") .. "/catppuccin-barista"
	if not vim.o.runtimepath:find(barista_rtp, 1, true) then
		vim.opt.runtimepath:append(barista_rtp)
	end

	-- (d) Ensure palette is always available
	--     Wrap get_palette so it re-injects before
	--     the original require() call
	local palettes = require("catppuccin.palettes")

	if not palettes._original_get_palette then
		palettes._original_get_palette = palettes.get_palette

		palettes.get_palette = function(flavour)
			local flvr = flavour or catppuccin.flavour or vim.g.catppuccin_flavour or "mocha"

			-- Re-inject in case modules were purged
			if M._flavours[flvr] then
				package.loaded["catppuccin.palettes." .. flvr] = M._flavours[flvr].palette
			end

			return palettes._original_get_palette(flavour)
		end
	end

	return true
end

---@class CatppuccinBaristaFlavourDef
---@field palette CatppuccinPalette
---@field opts? CatppuccinBaristaRegisterOpts

---@class CatppuccinBaristaConfig
---@field presets? string[]|boolean List of preset names to enable, or true for all
---@field flavours? table<string, CatppuccinBaristaFlavourDef> Custom flavour definitions

--- Get available preset names.
---@return string[]
function M.get_presets()
	local presets = require("catppuccin-barista.presets")
	return vim.tbl_keys(presets)
end

--- Convenience: register + apply in one shot.
---@param config CatppuccinBaristaConfig|table<string, CatppuccinBaristaFlavourDef> Config or legacy flavours map
function M.setup(config)
	config = config or {}

	-- Load presets
	if config.presets then
		local all_presets = require("catppuccin-barista.presets")

		local preset_names
		if config.presets == true then
			preset_names = vim.tbl_keys(all_presets)
		else
			preset_names = config.presets
		end

		for _, name in ipairs(preset_names) do
			local preset = all_presets[name]
			if preset then
				M.register(name, preset.palette, preset.opts)
			else
				vim.notify(("[catppuccin-barista] unknown preset '%s'"):format(name), vim.log.levels.WARN)
			end
		end
	end

	-- Load custom flavours
	if config.flavours then
		for name, def in pairs(config.flavours) do
			M.register(name, def.palette, def.opts)
		end
	end

	-- Shorthand: treat config as flavours map if no presets/flavours keys
	if not config.presets and not config.flavours then
		for name, def in pairs(config) do
			if type(def) == "table" and def.palette then
				M.register(name, def.palette, def.opts)
			end
		end
	end

	M.apply()
end

return M
