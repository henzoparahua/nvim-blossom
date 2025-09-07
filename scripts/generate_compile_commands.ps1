param(
    [Parameter(Mandatory=$true)]
    [string]$SolutionDirectory,
    [string]$Configuration = "Debug",
    [string]$Platform = "x64"
)

# Helper function to detect Visual Studio installation
function Find-VisualStudio {
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    
    if (Test-Path $vsWhere) {
        try {
            $vsInfo = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json | ConvertFrom-Json
            
            if ($vsInfo -and $vsInfo.Count -gt 0) {
                $vs = $vsInfo[0]
                return @{
                    InstallPath = $vs.installationPath
                    Version = $vs.installationVersion.Split('.')[0]
                }
            }
        } catch {
            Write-Warning "vswhere.exe failed: $($_.Exception.Message)"
        }
    }
    
    # Fallback detection
    $possiblePaths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional", 
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community",
        "${env:ProgramFiles}\Microsoft Visual Studio\2019\Enterprise",
        "${env:ProgramFiles}\Microsoft Visual Studio\2019\Professional",
        "${env:ProgramFiles}\Microsoft Visual Studio\2019\Community"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $version = if ($path -like "*2022*") { "17" } else { "16" }
            return @{
                InstallPath = $path
                Version = $version
            }
        }
    }
    
    throw "No Visual Studio installation found!"
}

# Helper function to find MSVC and Windows SDK versions
function Get-ToolchainVersions($vsPath) {
    # Find MSVC version
    $msvcPath = Join-Path $vsPath "VC\Tools\MSVC"
    $msvcVersion = ""
    
    if (Test-Path $msvcPath) {
        $versions = Get-ChildItem $msvcPath | Where-Object { $_.PSIsContainer } | Sort-Object Name -Descending
        if ($versions.Count -gt 0) {
            $msvcVersion = $versions[0].Name
        }
    }
    
    # Find Windows SDK version
    $sdkPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Include"
    $sdkVersion = ""
    
    if (Test-Path $sdkPath) {
        $versions = Get-ChildItem $sdkPath | Where-Object { $_.PSIsContainer -and $_.Name -match '^10\.' } | Sort-Object Name -Descending
        if ($versions.Count -gt 0) {
            $sdkVersion = $versions[0].Name
        }
    }
    
    # Fallback for SDK
    if (-not $sdkVersion) {
        $fallbackVersions = @("10.0.26100.0", "10.0.22621.0", "10.0.19041.0")
        foreach ($version in $fallbackVersions) {
            if (Test-Path "${env:ProgramFiles(x86)}\Windows Kits\10\Include\$version") {
                $sdkVersion = $version
                break
            }
        }
    }
    
    if (-not $msvcVersion) {
        throw "MSVC toolset not found!"
    }
    
    if (-not $sdkVersion) {
        $sdkVersion = "10.0.26100.0"  # Ultimate fallback
    }
    
    return @{
        MSVC = $msvcVersion
        WindowsSDK = $sdkVersion
    }
}

# Parse solution file to get projects
function Parse-SolutionFile($slnPath) {
    $slnContent = Get-Content $slnPath -Raw
    $projects = @()
    
    # Match project lines: Project("{GUID}") = "ProjectName", "ProjectPath", "{ProjectGUID}"
    $projectMatches = [regex]::Matches($slnContent, 'Project\("([^"]+)"\)\s*=\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)"')
    
    foreach ($match in $projectMatches) {
        $projectTypeGuid = $match.Groups[1].Value
        $projectName = $match.Groups[2].Value
        $projectPath = $match.Groups[3].Value
        $projectGuid = $match.Groups[4].Value
        
        # Only include C++ projects (Visual C++ project GUID)
        if ($projectTypeGuid -eq "{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") {
            $fullProjectPath = Join-Path (Split-Path $slnPath -Parent) $projectPath
            
            if (Test-Path $fullProjectPath) {
                $projects += @{
                    Name = $projectName
                    Path = $fullProjectPath
                    RelativePath = $projectPath
                    Guid = $projectGuid
                }
            }
        }
    }
    
    return $projects
}

# Parse project file to get source files and settings
function Parse-ProjectFile($projectPath, $solutionDir) {
    try {
        [xml]$projectXml = Get-Content $projectPath -Raw
    } catch {
        return @{ SourceFiles = @(); IncludePaths = @(); Defines = @() }
    }
    
    $projectDir = Split-Path $projectPath -Parent
    $sourceFiles = @()
    $includePaths = @()
    $defines = @()
    
    # Get source files (ClCompile items)
    $compileItems = $projectXml.Project.ItemGroup.ClCompile
    foreach ($item in $compileItems) {
        if ($item.Include) {
            $sourcePath = Join-Path $projectDir $item.Include
            if (Test-Path $sourcePath) {
                $sourceFiles += $sourcePath
            }
        }
    }
    
    # Get include paths from project properties
    $includePaths += $solutionDir  # Solution directory is always included
    $includePaths += $projectDir   # Project directory
    
    # Look for additional include paths in PropertyGroup
    $propertyGroups = $projectXml.Project.PropertyGroup
    foreach ($group in $propertyGroups) {
        if ($group.IncludePath) {
            $paths = $group.IncludePath -split ';'
            foreach ($path in $paths) {
                $cleanPath = $path.Trim()
                if ($cleanPath -and $cleanPath -ne '$(IncludePath)') {
                    # Replace common MSBuild variables
                    $cleanPath = $cleanPath -replace '\$\(SolutionDir\)', $solutionDir
                    $cleanPath = $cleanPath -replace '\$\(ProjectDir\)', $projectDir
                    
                    if ([System.IO.Path]::IsPathRooted($cleanPath)) {
                        $includePaths += $cleanPath
                    } else {
                        $includePaths += Join-Path $solutionDir $cleanPath
                    }
                }
            }
        }
    }
    
    # Get preprocessor definitions
    $itemDefGroups = $projectXml.Project.ItemDefinitionGroup
    foreach ($group in $itemDefGroups) {
        $condition = $group.Condition
        # Check if this group matches our configuration
        if (-not $condition -or ($condition -like "*$Configuration*" -and $condition -like "*$Platform*")) {
            if ($group.ClCompile -and $group.ClCompile.PreprocessorDefinitions) {
                $defs = $group.ClCompile.PreprocessorDefinitions -split ';'
                foreach ($def in $defs) {
                    $cleanDef = $def.Trim()
                    if ($cleanDef -and $cleanDef -ne '%(PreprocessorDefinitions)') {
                        $defines += $cleanDef
                    }
                }
            }
        }
    }
    
    return @{
        SourceFiles = $sourceFiles
        IncludePaths = ($includePaths | Sort-Object -Unique)
        Defines = ($defines | Sort-Object -Unique)
    }
}

# Main execution
try {
    # Validate solution directory
    if (-not (Test-Path $SolutionDirectory)) {
        throw "Solution directory not found: $SolutionDirectory"
    }
    
    # Find solution file
    $slnFiles = Get-ChildItem -Path $SolutionDirectory -Filter "*.sln" -File
    if ($slnFiles.Count -eq 0) {
        throw "No solution file found in directory: $SolutionDirectory"
    }
    
    $solutionFile = $slnFiles[0].FullName
    
    # Detect Visual Studio and toolchain
    $vsInfo = Find-VisualStudio
    $toolchain = Get-ToolchainVersions $vsInfo.InstallPath
    
    # Parse solution and projects
    $projects = Parse-SolutionFile $solutionFile
    if ($projects.Count -eq 0) {
        throw "No C++ projects found in solution!"
    }
    
    # Build system include paths - ordered for best compatibility
    $systemIncludes = @(
        # MSVC standard library first
        "$($vsInfo.InstallPath)\VC\Tools\MSVC\$($toolchain.MSVC)\include",
        # Windows SDK - UCRT first for C++ standard library
        "${env:ProgramFiles(x86)}\Windows Kits\10\Include\$($toolchain.WindowsSDK)\ucrt",
        # Windows API headers
        "${env:ProgramFiles(x86)}\Windows Kits\10\Include\$($toolchain.WindowsSDK)\um", 
        "${env:ProgramFiles(x86)}\Windows Kits\10\Include\$($toolchain.WindowsSDK)\shared",
        # WinRT and modern C++ support
        "${env:ProgramFiles(x86)}\Windows Kits\10\Include\$($toolchain.WindowsSDK)\winrt",
        "${env:ProgramFiles(x86)}\Windows Kits\10\Include\$($toolchain.WindowsSDK)\cppwinrt"
    )
    
    # Base compiler flags - optimized for C++20 and Windows development
    $baseFlags = @(
        "-std=c++20",
        "--target=x86_64-pc-windows-msvc",
        "-fms-extensions",
        "-fms-compatibility",
        "-fdelayed-template-parsing",
        "-DUNICODE",
        "-D_UNICODE",
        "-DWIN32_LEAN_AND_MEAN",
        "-DNOMINMAX",
        "-D_WIN32_WINNT=0x0A00",
        "-DWINVER=0x0A00",
        "-D_CRT_SECURE_NO_WARNINGS",
        "-D_SCL_SECURE_NO_WARNINGS",
        # Additional clangd compatibility flags
        "-Wno-pragma-once-outside-header",
        "-Wno-unknown-pragmas",
        "-Wno-microsoft-enum-value",
        "-Wno-unused-command-line-argument"
    )
    
    # Configuration-specific flags
    if ($Configuration -eq "Debug") {
        $baseFlags += "-D_DEBUG"
        $baseFlags += "-g"
    } else {
        $baseFlags += "-DNDEBUG"
        $baseFlags += "-O2"
    }
    
    # Platform-specific flags
    switch ($Platform.ToLower()) {
        "x64" { 
            $baseFlags += @("-D_WIN64", "-D_M_X64")
        }
        "x86" { 
            $baseFlags += @("-D_WIN32", "-D_M_IX86")
        }
        "arm64" { 
            $baseFlags += @("-D_WIN64", "-D_ARM64_", "-D_M_ARM64")
        }
    }
    
    # Process each project
    $allCompileCommands = @()
    $totalSourceFiles = 0
    
    foreach ($project in $projects) {
        $projectInfo = Parse-ProjectFile $project.Path $SolutionDirectory
        $totalSourceFiles += $projectInfo.SourceFiles.Count
        
        # Build complete include paths
        $allIncludes = @()
        $allIncludes += $projectInfo.IncludePaths
        $allIncludes += $systemIncludes
        
        # Build complete flags
        $compilerFlags = @()
        $compilerFlags += $baseFlags
        
        # Add project-specific defines
        foreach ($define in $projectInfo.Defines) {
            $compilerFlags += "-D$define"
        }
        
        # Add include flags
        foreach ($includePath in $allIncludes) {
            if (Test-Path $includePath) {
                if ($includePath -match '\s') {
                    $compilerFlags += "-I`"$includePath`""
                } else {
                    $compilerFlags += "-I$includePath"
                }
            }
        }
        
        # Build command string
        $commandString = "clang++ $($compilerFlags -join ' ')"
        
        # Create compile command entries
        foreach ($sourceFile in $projectInfo.SourceFiles) {
            $compileCommand = @{
                directory = $SolutionDirectory.Replace('\', '/')
                command = $commandString
                file = $sourceFile.Replace('\', '/')
            }
            $allCompileCommands += $compileCommand
        }
    }
    
    # Generate JSON output
    $json = $allCompileCommands | ConvertTo-Json -Depth 3
    $outputPath = Join-Path $SolutionDirectory "compile_commands.json"
    $json | Out-File -FilePath $outputPath -Encoding utf8
    
    # Output success info for Neovim to parse
    Write-Host "SUCCESS: Generated $($allCompileCommands.Count) entries for $($projects.Count) projects in $outputPath"
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
