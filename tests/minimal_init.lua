-- Minimal init for running tests
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"

if not vim.loop.fs_stat(plenary_path) then
	print("Cloning plenary.nvim...")
	vim.fn.system({
		"git",
		"clone",
		"--depth=1",
		"https://github.com/nvim-lua/plenary.nvim",
		plenary_path,
	})
end

vim.opt.runtimepath:append(plenary_path)
vim.opt.runtimepath:append(".")

vim.cmd("runtime plugin/plenary.vim")
