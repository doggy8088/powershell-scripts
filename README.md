# PowerShell Scripts Collection

A curated collection of useful PowerShell scripts for Windows environments, designed to enhance productivity and automate common tasks.

## Installation

**Default Installation Path**: `%userprofile%\Documents\PowerShell\Scripts`

Place all scripts in the above directory, which is automatically included in the PowerShell PATH. After installation, scripts can be executed directly by name without specifying the full path.

## Scripts Overview

### 🛠️ Installation and Setup Scripts

#### `Install-VSCode.ps1`
**Purpose**: Automated installation of Visual Studio Code with PowerShell extension support

**Features**:
- Supports both stable and insider editions
- Choose between system-wide or user profile installation
- Automatic PowerShell extension installation
- Support for additional extensions via parameter
- Context menu integration option
- Architecture selection (32-bit/64-bit)

**Usage Examples**:
```powershell
# Basic installation (64-bit stable system-wide)
Install-VSCode

# Install 32-bit version
Install-VSCode -Architecture 32-bit

# Install with additional extensions
Install-VSCode -AdditionalExtensions 'eamodio.gitlens', 'vscodevim.vim'

# Install insider edition for current user and launch when done
Install-VSCode -BuildEdition Insider-User -LaunchWhenDone
```

**Parameters**:
- `Architecture`: Choose between '64-bit' or '32-bit' (default: '64-bit')
- `BuildEdition`: 'Stable-System', 'Stable-User', 'Insider-System', 'Insider-User' (default: 'Stable-System')
- `AdditionalExtensions`: Array of extension IDs to install
- `LaunchWhenDone`: Launch VS Code after installation
- `EnableContextMenus`: Configure Explorer context menus

#### `Install-WTCanary.ps1`
**Purpose**: Install or update Windows Terminal Canary (preview) version

**Features**:
- Automatic version checking against current installation
- Downloads latest canary build from Microsoft
- Uses Windows Store app installation mechanism
- Progress reporting during installation

**Usage**:
```powershell
# Simple installation/update
Install-WTCanary
```

**Notes**:
- Requires Windows 10/11 with Microsoft Store support
- Uses Appx module for package management
- No parameters required - fully automated

### 📊 Analysis and Utility Scripts

#### `FolderLens.ps1`
**Purpose**: Analyze folder structures and file counts with flexible counting modes

**Features**:
- Two counting modes: Aggregate (recursive) or Direct (current level only)
- Path and name-based exclusion filters
- Customizable top-N results
- Object-oriented output for pipeline processing
- Hidden file inclusion option
- Built-in exclusion of system directories

**Usage Examples**:
```powershell
# Top 10 folders by total file count (including subfolders)
FolderLens -Path C:\Repos -TopN 10

# Top 5 folders by direct file count only, excluding node_modules and .git
FolderLens -Path C:\Repos -TopN 5 -Mode Direct -ExcludeName node_modules,.git

# Export results to CSV
FolderLens -Path D:\Data -TopN 20 | Export-Csv .\top20.csv -NoTypeInformation

# Include hidden files and system directories
FolderLens -Path C:\Projects -TopN 15 -IncludeHidden
```

**Parameters**:
- `Path`: Root directory to analyze (mandatory)
- `TopN`: Number of top results to return (mandatory, ≥1)
- `Mode`: 'Aggregate' (default) or 'Direct' counting mode
- `ExcludePath`: Array of full paths to exclude
- `ExcludeName`: Array of folder names to exclude
- `IncludeHidden`: Include hidden and system files

**Output**: Objects with `Path` and `FileCount` properties for easy processing

#### `Invoke-LinkChecker.ps1`
**Purpose**: PowerShell wrapper for the linkchecker command-line tool

**Features**:
- Comprehensive parameter mapping for linkchecker utility
- Support for multiple output formats (CSV, XML, HTML, etc.)
- Configurable threading and recursion levels
- Cookie and authentication support
- Debug logging capabilities
- Robots.txt compliance options

**Usage Examples**:
```powershell
# Basic website link checking
Invoke-LinkChecker -Url "https://example.com"

# Check with specific number of threads and recursion depth
Invoke-LinkChecker -Url "https://example.com" -Threads 5 -RecursionLevel 2

# Output to CSV file
Invoke-LinkChecker -Url "https://example.com" -Output csv -FileOutput results.csv

# Check external links and ignore robots.txt
Invoke-LinkChecker -Url "https://example.com" -CheckExtern -NoRobots
```

**Key Parameters**:
- `Url`: Website URL to check
- `Threads`: Number of concurrent threads
- `Output`: Format ('csv', 'xml', 'html', 'text', etc.)
- `RecursionLevel`: Maximum link depth to follow
- `CheckExtern`: Include external links
- `NoRobots`: Skip robots.txt checking

### 🤖 AI and Development Integration

#### `ghcs.ps1` (GitHub Copilot Suggest)
**Purpose**: Enhanced GitHub CLI integration with Copilot suggestions for PowerShell environments

**Features**:
- Seamless integration with GitHub Copilot CLI
- Target-specific suggestions (git, GitHub CLI, or shell commands)
- Command history integration
- Automatic command execution capability
- Debug mode support
- Windows PowerShell context awareness

**Usage Examples**:
```powershell
# Get shell command suggestions
ghcs "create a folder structure for a new project"

# Git-specific suggestions
ghcs -Target git "undo the last commit but keep changes"

# GitHub CLI suggestions
ghcs -Target gh "create a new repository"

# Enable debug mode
ghcs -Debug "help with PowerShell scripting"
```

**Parameters**:
- `Target`: 'shell' (default), 'git', or 'gh'
- `Prompt`: Natural language description of desired action
- `Debug`: Enable API debugging output

#### `ask.ps1`
**Purpose**: Quick AI assistant integration for content analysis and explanation

**Features**:
- Supports both command-line arguments and pipeline input
- Automatic content encoding and URL generation
- Integration with ChatGPT web interface
- Chinese language output optimization
- Chrome browser integration

**Usage Examples**:
```powershell
# Ask about a specific topic
ask "What is PowerShell remoting?"

# Analyze content from pipeline
Get-Content script.ps1 | ask

# Analyze command output
Get-Process | ask "explain this process list"
```

**Features**:
- Accepts input from arguments or pipeline
- Automatically encodes content for web transfer
- Opens results in Chrome browser
- Optimized for Chinese language responses

## 🔐 Security and Code Signing

Several scripts in this collection are digitally signed for enhanced security. See [`AuthenticodeSignature_Notes.md`](AuthenticodeSignature_Notes.md) for detailed information about:

- Code signing procedures
- Certificate management
- Signature verification
- Unblocking downloaded scripts

## 📋 System Requirements

- **Operating System**: Windows 10/11
- **PowerShell**: PowerShell 7+ recommended (Windows PowerShell 5.1 compatible)
- **Execution Policy**: May require `RemoteSigned` or `Unrestricted` execution policy
- **Dependencies**: 
  - GitHub CLI (`gh`) for `ghcs.ps1`
  - linkchecker utility for `Invoke-LinkChecker.ps1`
  - Chrome browser for `ask.ps1`

## 🚀 Getting Started

1. **Set Execution Policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Create Scripts Directory**:
   ```powershell
   $scriptsPath = "$env:USERPROFILE\Documents\PowerShell\Scripts"
   if (!(Test-Path $scriptsPath)) { New-Item -Path $scriptsPath -ItemType Directory }
   ```

3. **Download Scripts**: Clone this repository or download individual scripts to the directory

4. **Verify Installation**:
   ```powershell
   Get-Command Install-VSCode  # Should show the script location
   ```

5. **Run Scripts**: Execute directly by name from any PowerShell session

## 🛡️ Troubleshooting

### Common Issues

**Script Not Found**:
- Verify scripts are in `%userprofile%\Documents\PowerShell\Scripts`
- Restart PowerShell session after adding new scripts
- Use `Get-Command <scriptname>` to verify accessibility

**Execution Policy Errors**:
- Check current policy: `Get-ExecutionPolicy`
- Set appropriate policy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- For signed scripts, ensure signatures are valid

**Module Dependencies**:
- Some scripts require specific modules (e.g., Appx for Windows Store apps)
- Import modules as shown in script examples
- Check script documentation for specific requirements

### Getting Help

Each script includes comprehensive help documentation:
```powershell
Get-Help Install-VSCode -Full
Get-Help FolderLens -Examples
```

## 🤝 Contributing

This repository follows PowerShell best practices and includes AI-assisted development guidelines. See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) for detailed contribution guidelines and coding standards.

## 📄 License

Individual scripts may have specific licenses. Check PSScriptInfo headers in each script for licensing information. Many scripts are MIT licensed or follow their original project licenses.
