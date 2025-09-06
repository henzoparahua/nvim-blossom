-- Complete C++ and HLSL configuration
return {
  -- LSP and Language Server Setup
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
        settings = {
          clangd = {
            InlayHints = {
              Enabled = true,
              ParameterNames = true,
              DeducedTypes = true,
            },
            fallbackFlags = { "-std=c++20" },
          },
        },
        capabilities = {
          offsetEncoding = { "utf-16" },
        },
      }

      opts.setup = opts.setup or {}
      opts.setup.clangd = function(_, server_opts)
        require("clangd_extensions").setup(vim.tbl_deep_extend("force", {}, { server = server_opts }))
        return false
      end

      return opts
    end,
    init = function()
      -- HLSL file type recognition
      vim.filetype.add({
        extension = {
          hlsl = "hlsl",
          hlsli = "hlsl",
          fx = "hlsl",
          fxh = "hlsl",
          vsh = "hlsl",
          psh = "hlsl",
          compute = "hlsl",
        },
      })

      -- C++ file settings
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c", "cpp", "hlsl" },
        callback = function()
          vim.opt_local.shiftwidth = 4
          vim.opt_local.tabstop = 4
          vim.opt_local.expandtab = true
          vim.opt_local.textwidth = 120
          vim.opt_local.colorcolumn = "120"
          if vim.bo.filetype ~= "hlsl" then
            vim.opt_local.cindent = true
          end
          if vim.bo.filetype == "hlsl" then
            vim.opt_local.commentstring = "// %s"
          end
        end,
      })
    end,
  },

  -- Clangd Extensions
  {
    "p00f/clangd_extensions.nvim",
    lazy = true,
    opts = {
      inlay_hints = { inline = false },
    },
  },

  -- Mason (Tool Management)
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "clangd", -- C++ LSP
        "clang-format", -- C++ formatter
        "codelldb", -- Debugger (optional)
      },
    },
  },

  -- Enhanced Treesitter for C++ and HLSL
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "c", "cpp", "hlsl", "glsl", "json", "xml" })
      end
    end,
  },

  -- C++ Keymaps and Commands
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>cx", group = "+C++/DirectX" },
      },
    },
  },

  -- C++ specific keymaps - using LazyKeys format
  {
    "neovim/nvim-lspconfig",
    keys = {
      -- Clangd commands
      { "<leader>cxs", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header", ft = { "c", "cpp" } },
      { "<leader>cxt", "<cmd>ClangdTypeHierarchy<cr>", desc = "Type Hierarchy", ft = { "c", "cpp" } },
      -- Visual Studio integration
      {
        "<leader>cxo",
        function()
          local file = vim.fn.expand("%:p")
          vim.fn.system(
            'start "" "C:\\Program Files\\Microsoft Visual Studio\\2022\\Professional\\Common7\\IDE\\devenv.exe" "'
              .. file
              .. '"'
          )
        end,
        desc = "Open in Visual Studio",
        ft = { "c", "cpp" },
      },
      -- Quick compile with MSVC
      {
        "<leader>cxc",
        function()
          local file = vim.fn.expand("%:p")
          local output = vim.fn.expand("%:p:r") .. ".exe"
          local cmd = string.format('cl /std:c++20 /EHsc "%s" /Fe:"%s"', file, output)
          vim.cmd("split | terminal " .. cmd)
        end,
        desc = "Compile (MSVC)",
        ft = { "cpp" },
      },
      -- Include guard
      {
        "<leader>cxi",
        function()
          local filename = vim.fn.expand("%:t:r"):upper() .. "_H"
          local guard = filename:gsub("[^A-Z0-9_]", "_")
          local lines = {
            "#ifndef " .. guard,
            "#define " .. guard,
            "",
            "",
            "",
            "#endif // " .. guard,
          }
          vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
          vim.api.nvim_win_set_cursor(0, { 4, 0 })
        end,
        desc = "Insert Include Guard",
        ft = { "c", "cpp" },
      },
    },
  },

  -- Enhanced C++ syntax highlighting
  {
    "bfrg/vim-cpp-modern",
    ft = { "c", "cpp" },
    config = function()
      vim.g.cpp_class_scope_highlight = 1
      vim.g.cpp_member_variable_highlight = 1
      vim.g.cpp_class_decl_highlight = 1
      vim.g.cpp_experimental_template_highlight = 1
      vim.g.cpp_concepts_highlight = 1
    end,
  },

  -- HLSL syntax highlighting
  {
    "tikhomirov/vim-glsl",
    ft = { "glsl", "hlsl" },
  },

  -- Better auto-pairs for C++
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")
      npairs.setup({})
      -- Add custom rules for C++
      npairs.add_rules({
        -- Template brackets
        Rule("<", ">", { "cpp", "c" }):with_pair(function(args)
          local before_text = args.line:sub(1, args.col - 1)
          return before_text:match("template%s*$") or before_text:match("std::")
        end),
        -- Include quotes
        Rule('"', '"', { "cpp", "c" }):with_pair(function(args)
          local before_text = args.line:sub(1, args.col - 1)
          return before_text:match("#include%s*$")
        end),
      })
    end,
  },

  -- TODO comments
  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
      },
    },
  },
}
