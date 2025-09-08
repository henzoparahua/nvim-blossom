-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable mouse support (keyboard-only mode)
vim.opt.mouse = ""

-- Enable transparent background
vim.g.transparent_enabled = true

-- Statusline configuration for staline.nvim
vim.opt.laststatus = 2 -- Always show statusline
vim.opt.termguicolors = true -- Enable true colors (required for staline)

-- Line number configuration
vim.opt.number = true         -- Show absolute line numbers
vim.opt.relativenumber = false -- Disable relative line numbers

-- Load transparency configuration
require("config.transparency")
