-- compile_commands.lua - Simple auto-generation of compile_commands.json for Visual Studio projects
local M = {}

-- Configuration
local config = {
  configuration = "Debug",
  platform = "x64",
  debounce_delay = 2000,
  auto_regenerate = true,
  restart_clangd = true,
}

-- Internal state
local timer = nil
local script_path = nil

-- Helper function to find script path
local function get_script_path()
  if script_path then
    return script_path
  end
  
  local possible_paths = {
    vim.fn.stdpath('config') .. '/scripts/generate_compile_commands.ps1',
    vim.fn.stdpath('data') .. '/scripts/generate_compile_commands.ps1',
    os.getenv('LOCALAPPDATA') .. '/nvim/scripts/generate_compile_commands.ps1'
  }
  
  for _, path in ipairs(possible_paths) do
    if vim.fn.filereadable(path) == 1 then
      script_path = path
      return script_path
    end
  end
  return nil
end

-- Helper function to find solution directory
local function find_solution_directory(start_path)
  local current_dir = start_path or vim.fn.getcwd()
  
  while current_dir and current_dir ~= "/" and current_dir ~= "" do
    local sln_files = vim.fn.glob(current_dir .. '/*.sln', false, true)
    if #sln_files > 0 then
      return current_dir
    end
    
    local parent = vim.fn.fnamemodify(current_dir, ':h')
    if parent == current_dir then
      break
    end
    current_dir = parent
  end
  
  return nil
end

-- Main function to regenerate compile_commands.json
local function regenerate_compile_commands(solution_dir, force_config)
  local script = get_script_path()
  if not script then
    vim.notify("PowerShell script not found", vim.log.levels.ERROR)
    return false
  end
  
  if not solution_dir then
    solution_dir = find_solution_directory()
    if not solution_dir then
      vim.notify("No Visual Studio solution found", vim.log.levels.WARN)
      return false
    end
  end
  
  local cfg = force_config or config
  
  vim.notify("Generating compile_commands.json...", vim.log.levels.INFO)
  
  local ps_cmd = string.format(
    'powershell -ExecutionPolicy Bypass -File "%s" -SolutionDirectory "%s" -Configuration "%s" -Platform "%s"',
    script,
    solution_dir,
    cfg.configuration,
    cfg.platform
  )
  
  vim.fn.jobstart(ps_cmd, {
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            if line:match("^SUCCESS:") then
              local msg = line:gsub("^SUCCESS: ", "")
              vim.notify("Success: " .. msg, vim.log.levels.INFO)
            elseif line:match("^ERROR:") then
              local msg = line:gsub("^ERROR: ", "")
              vim.notify("Error: " .. msg, vim.log.levels.ERROR)
            end
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          if cfg.restart_clangd then
            local clients = vim.lsp.get_active_clients({ name = "clangd" })
            if #clients > 0 then
              vim.cmd("LspRestart clangd")
              vim.notify("Restarted clangd", vim.log.levels.INFO)
            end
          end
        else
          vim.notify("Failed to generate compile_commands.json", vim.log.levels.ERROR)
        end
      end)
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })
  
  return true
end

-- Debounced regeneration function
local function regenerate_debounced()
  if timer then
    timer:stop()
    timer:close()
  end
  
  timer = vim.loop.new_timer()
  timer:start(config.debounce_delay, 0, vim.schedule_wrap(function()
    regenerate_compile_commands()
    
    if timer then
      timer:close()
      timer = nil
    end
  end))
end

-- Setup function
function M.setup(opts)
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end
  
  local script = get_script_path()
  if not script then
    vim.notify("Compile Commands: PowerShell script not found", vim.log.levels.ERROR)
    return
  end
  
  local group = vim.api.nvim_create_augroup("CompileCommandsAuto", { clear = true })
  
  if config.auto_regenerate then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      pattern = { "*.sln", "*.vcxproj", "*.vcxproj.filters", "*.props", "*.targets" },
      callback = regenerate_debounced,
      desc = "Auto-regenerate compile_commands.json"
    })
  end
  
  -- Create user commands
  vim.api.nvim_create_user_command("UpdateCompileCommands", function()
    regenerate_compile_commands()
  end, { desc = "Generate compile_commands.json" })
  
  vim.api.nvim_create_user_command("UpdateCompileCommandsDebug", function()
    regenerate_compile_commands(nil, { configuration = "Debug", platform = "x64" })
  end, { desc = "Generate compile_commands.json (Debug)" })
  
  vim.api.nvim_create_user_command("UpdateCompileCommandsRelease", function()
    regenerate_compile_commands(nil, { configuration = "Release", platform = "x64" })
  end, { desc = "Generate compile_commands.json (Release)" })
  
  -- Create keybindings
  vim.keymap.set('n', '<leader>cc', regenerate_compile_commands, { desc = 'Update Compile Commands' })
  
  vim.notify("Compile Commands integration loaded", vim.log.levels.INFO)
end

-- Manual regeneration function
function M.regenerate(opts)
  opts = opts or {}
  local solution_dir = opts.solution_dir or find_solution_directory()
  local force_config = {
    configuration = opts.configuration or config.configuration,
    platform = opts.platform or config.platform,
    restart_clangd = opts.restart_clangd ~= nil and opts.restart_clangd or config.restart_clangd
  }
  
  return regenerate_compile_commands(solution_dir, force_config)
end

-- Debug function
function M.debug()
  print("=== COMPILE COMMANDS DEBUG ===")
  print("Current working directory: " .. vim.fn.getcwd())
  
  local script = get_script_path()
  print("Script found: " .. (script or "NOT FOUND"))
  
  local solution_dir = find_solution_directory()
  print("Solution directory: " .. (solution_dir or "NOT FOUND"))
  
  if solution_dir then
    local sln_files = vim.fn.glob(solution_dir .. '/*.sln', false, true)
    print("Solution files found: " .. #sln_files)
    for _, file in ipairs(sln_files) do
      print("  - " .. file)
    end
  end
  
  print("=== END DEBUG ===")
end

return M
