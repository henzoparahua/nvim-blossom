return {
  "tamton-aquib/staline.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.opt.laststatus = 2
    vim.opt.termguicolors = true

    require("staline").setup({
      sections = {
        left = { " ", "mode", " ", "branch" },
        mid = { "lsp" },
        right = {
          function()
            local filename = vim.fn.expand("%:t")
            if filename == "" then
              filename = "[No Name]"
            end
            return "%#StalineFile#" .. filename .. "%*"
          end,
          "line_column",
        },
      },
      mode_colors = {
        i = "#d4be98",
        n = "#84a598",
        c = "#8fbf7f",
        v = "#fc802d",
      },
      defaults = {
        true_colors = true,
        line_column = " [%l/%L] :%c  ",
        branch_symbol = " ",
        file_name = "%t", -- Show only filename without icon
      },
    })
    vim.cmd([[ hi Evil guifg=#f36365 guibg=NONE ]])
    vim.cmd([[ hi StalineEnc guifg=#7d9955 guibg=NONE ]])
    vim.cmd([[ hi StalineGit guifg=#7aa2f7 guibg=NONE ]])
    vim.cmd([[ hi StalineFile guifg=#c0caf5 guibg=NONE ]])
  end,
}
