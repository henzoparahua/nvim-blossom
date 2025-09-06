local function set_transparent_bg()
  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "TabLine", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "TabLineSel", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "VertSplit", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "WinSeparator", { bg = "NONE", ctermbg = "NONE" })

  -- Telescope
  vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "NONE", ctermbg = "NONE" })

  -- NvimTree
  vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "NONE", ctermbg = "NONE" })

  -- Staline statusline
  vim.api.nvim_set_hl(0, "Staline", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "StalineMode", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "StalineBranch", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "StalineFile", { bg = "NONE", ctermbg = "NONE" })
  vim.api.nvim_set_hl(0, "StalineLsp", { bg = "NONE", ctermbg = "NONE" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = set_transparent_bg,
  desc = "Set transparent background after colorscheme loads",
})

set_transparent_bg()
