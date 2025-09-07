# Visual Studio 2022 Integration for Neovim

Visual Studio 2022 is excellent for C++ project management, IntelliSense, and building. However, some DUMB developers (me) prefer Neovim for coding. This integration bridges that gap by automatically generating `compile_commands.json` files that enable clangd to provide the same IntelliSense capabilities in Neovim.

## What it does

- Parses Visual Studio solution (.sln) and project (.vcxproj) files
- Generates `compile_commands.json` with proper C++20 and Windows SDK support
- Auto-detects Visual Studio installation and toolchain versions
- Automatically regenerates when project files change
- Provides MSVC compatibility flags for accurate clangd analysis

## Requirements

- Visual Studio 2022 (any edition)
- Neovim with clangd LSP
- PowerShell (included with Windows)

## Usage

The integration works automatically once installed. When you open a Visual Studio C++ project in Neovim:

1. The tool detects your solution file
2. Parses all C++ projects in the solution
3. Generates `compile_commands.json` with correct flags and include paths
4. clangd provides IntelliSense based on your actual project configuration

Manual commands are available:
- `<Space>cc` - Generate compile commands for current configuration
- `<Space>cd` - Generate compile commands for Debug configuration
- `<Space>cr` - Generate compile commands for Release configuration
- `:UpdateCompileCommands` - Command mode alternative

## Workflow

Continue using Visual Studio 2022 for:
- Project creation and management
- Solution configuration
- Building and debugging
- Package management (vcpkg, NuGet)

Use Neovim for:
- Code editing with full IntelliSense
- Version control operations

The integration ensures your Neovim environment stays synchronized with your Visual Studio project settings automatically.

## Benefits

- Maintain Visual Studio's project management capabilities
- Get accurate C++20 and Windows SDK IntelliSense in Neovim
- Automatic synchronization with project changes
- No manual configuration required, just put this shit inside the nvim structure.
- Works with existing Visual Studio workflows
