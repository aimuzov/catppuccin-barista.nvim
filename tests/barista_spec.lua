local barista = require("catppuccin-barista")

-- Valid test palette with all 26 required keys
local valid_palette = {
	rosewater = "#f5e0dc",
	flamingo = "#f2cdcd",
	pink = "#f5c2e7",
	mauve = "#cba6f7",
	red = "#f38ba8",
	maroon = "#eba0ac",
	peach = "#fab387",
	yellow = "#f9e2af",
	green = "#a6e3a1",
	teal = "#94e2d5",
	sky = "#89dceb",
	sapphire = "#74c7ec",
	blue = "#89b4fa",
	lavender = "#b4befe",
	text = "#cdd6f4",
	subtext1 = "#bac2de",
	subtext0 = "#a6adc8",
	overlay2 = "#9399b2",
	overlay1 = "#7f849c",
	overlay0 = "#6c7086",
	surface2 = "#585b70",
	surface1 = "#45475a",
	surface0 = "#313244",
	base = "#1e1e2e",
	mantle = "#181825",
	crust = "#11111b",
}

-- Helper to reset state between tests
local function reset_barista()
	barista._flavours = {}
end

describe("catppuccin-barista", function()
	before_each(function()
		reset_barista()
	end)

	describe("register()", function()
		it("should register a valid flavour", function()
			local result = barista.register("test_theme", valid_palette)

			assert.is_true(result)
			assert.is_not_nil(barista._flavours["test_theme"])
			assert.are.same(valid_palette, barista._flavours["test_theme"].palette)
		end)

		it("should set default background to dark", function()
			barista.register("test_theme", valid_palette)

			assert.are.equal("dark", barista._flavours["test_theme"].background)
		end)

		it("should accept custom background option", function()
			barista.register("light_theme", valid_palette, { background = "light" })

			assert.are.equal("light", barista._flavours["light_theme"].background)
		end)

		it("should reject empty name", function()
			local result = barista.register("", valid_palette)

			assert.is_false(result)
			assert.is_nil(barista._flavours[""])
		end)

		it("should reject nil name", function()
			local result = barista.register(nil, valid_palette)

			assert.is_false(result)
		end)

		it("should reject name with invalid characters", function()
			local result = barista.register("test theme", valid_palette)
			assert.is_false(result)

			result = barista.register("test/theme", valid_palette)
			assert.is_false(result)

			result = barista.register("test.theme", valid_palette)
			assert.is_false(result)
		end)

		it("should accept name with valid characters", function()
			local result = barista.register("test_theme-123", valid_palette)

			assert.is_true(result)
		end)

		it("should reject palette with missing keys", function()
			local incomplete_palette = {
				rosewater = "#f5e0dc",
				flamingo = "#f2cdcd",
				-- missing other keys
			}

			local result = barista.register("incomplete", incomplete_palette)

			assert.is_false(result)
			assert.is_nil(barista._flavours["incomplete"])
		end)

		it("should deep copy the palette", function()
			local palette_copy = vim.deepcopy(valid_palette)
			barista.register("test_theme", palette_copy)

			palette_copy.rosewater = "#000000"

			assert.are_not.equal("#000000", barista._flavours["test_theme"].palette.rosewater)
		end)
	end)

	describe("unregister()", function()
		it("should remove a registered flavour", function()
			barista.register("test_theme", valid_palette)
			local result = barista.unregister("test_theme")

			assert.is_true(result)
			assert.is_nil(barista._flavours["test_theme"])
		end)

		it("should return false for non-existent flavour", function()
			local result = barista.unregister("non_existent")

			assert.is_false(result)
		end)

		it("should clear package.loaded entry", function()
			barista.register("test_theme", valid_palette)
			package.loaded["catppuccin.palettes.test_theme"] = valid_palette

			barista.unregister("test_theme")

			assert.is_nil(package.loaded["catppuccin.palettes.test_theme"])
		end)
	end)

	describe("get_presets()", function()
		it("should return a table", function()
			local presets = barista.get_presets()

			assert.is_table(presets)
		end)

		it("should include espresso preset", function()
			local presets = barista.get_presets()

			assert.is_true(vim.tbl_contains(presets, "espresso"))
		end)

		it("should include all expected presets", function()
			local presets = barista.get_presets()
			local expected = {
				"darkroast",
				"draculatte",
				"espresso",
				"gruvbrew",
				"kanagato",
				"nightbrew",
				"nordiccino",
				"rosetto",
				"solarbica",
			}

			for _, name in ipairs(expected) do
				assert.is_true(vim.tbl_contains(presets, name), "Missing preset: " .. name)
			end
		end)
	end)

	describe("presets", function()
		it("should load espresso preset with valid palette", function()
			local presets = require("catppuccin-barista.presets")

			assert.is_not_nil(presets.espresso)
			assert.is_not_nil(presets.espresso.palette)
			assert.is_not_nil(presets.espresso.palette.base)
		end)

		it("should have all 26 keys in each preset", function()
			local presets = require("catppuccin-barista.presets")
			local required_keys = {
				"rosewater", "flamingo", "pink", "mauve", "red", "maroon",
				"peach", "yellow", "green", "teal", "sky", "sapphire",
				"blue", "lavender", "text", "subtext1", "subtext0",
				"overlay2", "overlay1", "overlay0", "surface2", "surface1",
				"surface0", "base", "mantle", "crust",
			}

			for name, preset in pairs(presets) do
				for _, key in ipairs(required_keys) do
					assert.is_not_nil(
						preset.palette[key],
						string.format("Preset '%s' missing key '%s'", name, key)
					)
				end
			end
		end)
	end)

	describe("setup()", function()
		it("should register presets when presets = true", function()
			-- Mock catppuccin to avoid requiring it
			package.loaded["catppuccin"] = {
				flavours = {},
				setup = function() end,
			}
			package.loaded["catppuccin.palettes"] = {
				get_palette = function() return {} end,
			}

			barista.setup({ presets = true }, {})

			assert.is_not_nil(barista._flavours["espresso"])
			assert.is_not_nil(barista._flavours["draculatte"])

			-- Cleanup
			package.loaded["catppuccin"] = nil
			package.loaded["catppuccin.palettes"] = nil
		end)

		it("should register specific presets", function()
			package.loaded["catppuccin"] = {
				flavours = {},
				setup = function() end,
			}
			package.loaded["catppuccin.palettes"] = {
				get_palette = function() return {} end,
			}

			barista.setup({ presets = { "espresso", "gruvbrew" } }, {})

			assert.is_not_nil(barista._flavours["espresso"])
			assert.is_not_nil(barista._flavours["gruvbrew"])
			assert.is_nil(barista._flavours["draculatte"])

			package.loaded["catppuccin"] = nil
			package.loaded["catppuccin.palettes"] = nil
		end)

		it("should register custom flavours", function()
			package.loaded["catppuccin"] = {
				flavours = {},
				setup = function() end,
			}
			package.loaded["catppuccin.palettes"] = {
				get_palette = function() return {} end,
			}

			barista.setup({
				flavours = {
					custom_theme = { palette = valid_palette },
				},
			}, {})

			assert.is_not_nil(barista._flavours["custom_theme"])

			package.loaded["catppuccin"] = nil
			package.loaded["catppuccin.palettes"] = nil
		end)

		it("should support legacy API (direct flavours map)", function()
			package.loaded["catppuccin"] = {
				flavours = {},
				setup = function() end,
			}
			package.loaded["catppuccin.palettes"] = {
				get_palette = function() return {} end,
			}

			barista.setup({
				legacy_theme = { palette = valid_palette },
			}, {})

			assert.is_not_nil(barista._flavours["legacy_theme"])

			package.loaded["catppuccin"] = nil
			package.loaded["catppuccin.palettes"] = nil
		end)
	end)

	describe("apply()", function()
		it("should return true when no flavours registered", function()
			local result = barista.apply()

			assert.is_true(result)
		end)

		it("should return false when catppuccin not installed", function()
			package.loaded["catppuccin"] = nil
			barista.register("test_theme", valid_palette)

			local result = barista.apply()

			assert.is_false(result)
		end)

		it("should inject palette into package.loaded", function()
			package.loaded["catppuccin"] = {
				flavours = {},
				setup = function() end,
			}
			package.loaded["catppuccin.palettes"] = {
				get_palette = function() return {} end,
			}

			barista.register("test_theme", valid_palette)
			barista.apply()

			assert.is_not_nil(package.loaded["catppuccin.palettes.test_theme"])

			package.loaded["catppuccin"] = nil
			package.loaded["catppuccin.palettes"] = nil
			package.loaded["catppuccin.palettes.test_theme"] = nil
		end)

		it("should add flavour to catppuccin.flavours table", function()
			local catppuccin_mock = {
				flavours = { mocha = 1, latte = 2 },
				setup = function() end,
			}
			package.loaded["catppuccin"] = catppuccin_mock
			package.loaded["catppuccin.palettes"] = {
				get_palette = function() return {} end,
			}

			barista.register("test_theme", valid_palette)
			barista.apply()

			assert.is_not_nil(catppuccin_mock.flavours["test_theme"])
			assert.are.equal(3, catppuccin_mock.flavours["test_theme"])

			package.loaded["catppuccin"] = nil
			package.loaded["catppuccin.palettes"] = nil
		end)
	end)
end)
