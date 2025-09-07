-- Visual Studio compile_commands.json integration
return {
  {
    "compile-commands",
    dir = vim.fn.stdpath("config"),
    name = "compile-commands",
    config = function()
      -- Load the compile_commands module
      local compile_commands = require('compile_commands')
      
      -- Setup with configuration optimized for Visual Studio workflow
      compile_commands.setup({
        -- Default build configuration
        configuration = "Debug",
        
        -- Default platform  
        platform = "x64",
        
        -- Delay before regenerating (2 seconds to avoid spam)
        debounce_delay = 2000,
        
        -- Auto-regenerate when VS project files change
        auto_regenerate = true,
        
        -- Restart clangd after regenerating for immediate LSP update
        restart_clangd = true,
      })
      
      -- Additional keybindings for quick access
      vim.keymap.set('n', '<leader>cd', function()
        compile_commands.regenerate({ configuration = "Debug" })
      end, { desc = 'Update Compile Commands (Debug)' })
      
      vim.keymap.set('n', '<leader>cr', function()
        compile_commands.regenerate({ configuration = "Release" })
      end, { desc = 'Update Compile Commands (Release)' })
      
      -- Debug command
      vim.api.nvim_create_user_command("CompileCommandsDebug", function()
        compile_commands.debug()
      end, { desc = "Debug compile commands integration" })
    end,
    event = "VeryLazy",
  },
}
