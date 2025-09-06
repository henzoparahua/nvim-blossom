return {
  -- Disable LazyVim's dashboard
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
    },
  },
  -- Enable dashboard-nvim instead
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    cmd = "Dashboard",
    opts = function()
    local logo = [[
                                                                     
                             ::--::-=+===                          
                         :::-----------=+=+-=                      
                      ----------====----=====-=----:               
                     -:-------===========++=-=-----::              
                    ---===============++++======--:::              
           -----------------=====+++++++++++++++=++===---::::--:    
         ----------------===++++++++********+***+++==-:::-=++++===  
          ::----=++++******************++++======+********++=       
       ::--=+++*********######**+++++++++++++++++*#####***+-==--   
      ::--++****#*#########*========+***********+--=+*####*=-==--  
       :--++**###########*========++=---====++**##=---==+*#*-:-=   
      --==+***####%%%#*=======+++++*+----====+++++=---==+++=-::-::- 
       --==+**#*###*+=====++**++++****-----===+++++----==+++--:---:-
 -------===++*++++++++++++*******++++***------===+++=---==+++=-::-::::
 --------===+*#***********#***##%**++++++------====++=--==+*+==::---:::-
:-------====*##%########**##%%%%%*++++++------====++--==+**++-----:::::--
 -------=+++*++#%%%##%%#++*#%%*+*#%#*+=+++------===++=-==+**++------:::::-----
---===-=+**##*###%%##**####%%%*==+#*+==++=------==++==+*##++--=-=-:::::---::::-
----==-=***#%#%@%%%%%###%%@@@#+-==**+==+=------=++==+*##*+-==-=-::::::---:::::-
------===+###%%%@@%##%%%%%#%%@@+--=+++===------=+==+*##*+-==-=-:::::::----:::::
-------===++*#######**###%%%@@**+=--+++===-----++=+*##*+===-=-:::::::-----:::::
 -------====+++*#%%%%%%%%%###%%%+==--=+===-----+=+*%#*+=+=-=::--::::-----::::::
 -----=---=====+*++***##%%%%@@@@#====-=+===---=+=*##*+=+=--::--::::-----:::::-
  --------========+********####%@%+====-+=----===##*+=+=--::--::::--------     
   ---------=====++====++++*#%%%%*=*+====-==-----+#**=+=---::-::::-----        
      ----------=====+++++++*******+*+=+=======-:--+**=++---:::::::---         
       -----------=====++*******####%#*+==+======-:-**==+=--::::::---          
                                                                     
    ]]

    logo = string.rep("\n", 1) .. logo .. "\n\n"

    local opts = {
      theme = "doom",
      hide = {
        statusline = false,
      },
      config = {
        header = vim.split(logo, "\n"),
        center = {
          { action = "Telescope find_files", desc = " Find File", key = "f" },
          { action = "ene | startinsert", desc = " New File", key = "n" },
          { action = "Telescope oldfiles", desc = " Recent Files", key = "r" },
          { action = "Telescope live_grep", desc = " Find Text", key = "g" },
          { action = "e $MYVIMRC", desc = " Config", key = "c" },
          { action = 'eval require("lazy").sync()', desc = " Lazy Sync", key = "s" },
          { action = "qa", desc = " Quit", key = "q" },
        },
        footer = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          return { "Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
        end,
      },
    }

    for _, button in ipairs(opts.config.center) do
      button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
      button.key_format = "  %s"
    end

    -- Close Lazy and re-open when the dashboard is ready
    if vim.o.filetype == "lazy" then
      vim.cmd.close()
      vim.api.nvim_create_autocmd("User", {
        pattern = "DashboardLoaded",
        callback = function()
          require("lazy").show()
        end,
      })
    end

    return opts
    end,
  },
}
