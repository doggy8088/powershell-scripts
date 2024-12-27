<#PSScriptInfo

.VERSION 1.4.3

.GUID 539e5585-7a02-4dd6-b9a6-5dd288d0a5d0

.AUTHOR Microsoft

.COMPANYNAME Microsoft Corporation

.COPYRIGHT (c) Microsoft Corporation

.TAGS install vscode installer

.LICENSEURI https://github.com/PowerShell/vscode-powershell/blob/main/LICENSE.txt

.PROJECTURI https://github.com/PowerShell/vscode-powershell/blob/main/scripts/Install-VSCode.ps1

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    02/06/2021 - Fix an architecture check issue with non-English localizations.
    --
    01/04/2021 - Fix host for downloading VSCode.
    --
    07/10/2019 - Fix a version check when installing user-builds with Windows Powershell greater than 5.
    --
    30/08/2019 - Added functionality to install the "User Install" variant of Stable Edition.
    --
    07/11/2018 - Added support for PowerShell Core and macOS/Linux platforms.
    --
    15/08/2018 - Added functionality to install the new "User Install" variant of Insiders Edition.
    --
    21/03/2018 - Added functionality to install the VSCode context menus.
                 Also, VSCode is now always added to the search path.
    --
    20/03/2018 - Fix OS detection to prevent error
    --
    28/12/2017 - Added functionality to support 64-bit versions of VSCode
                 and support for installation of VSCode Insiders Edition.
    --
    Initial release.
#>

<#
.SYNOPSIS
    Installs Visual Studio Code, the PowerShell extension, and optionally
    a list of additional extensions.

.DESCRIPTION
    This script can be used to easily install Visual Studio Code and the
    PowerShell extension on your machine.  You may also specify additional
    extensions to be installed using the -AdditionalExtensions parameter.
    The -LaunchWhenDone parameter will cause VS Code to be launched as
    soon as installation has completed.

    Please contribute improvements to this script on GitHub!

    https://github.com/PowerShell/vscode-powershell/blob/main/scripts/Install-VSCode.ps1

.PARAMETER Architecture
    A validated string defining the bit version to download. Values can be either 64-bit or 32-bit.
    If 64-bit is chosen and the OS Architecture does not match, then the 32-bit build will be
    downloaded instead. If parameter is not used, then 64-bit is used as default.

.PARAMETER BuildEdition
    A validated string defining which build edition or "stream" to download:
    Stable or Insiders Edition (system install or user profile install).
    If the parameter is not used, then stable is downloaded as default.


.PARAMETER AdditionalExtensions
    An array of strings that are the fully-qualified names of extensions to be
    installed in addition to the PowerShell extension.  The fully qualified
    name is formatted as "<publisher name>.<extension name>" and can be found
    next to the extension's name in the details tab that appears when you
    click an extension in the Extensions panel in Visual Studio Code.

.PARAMETER LaunchWhenDone
    When present, causes Visual Studio Code to be launched as soon as installation
    has finished.

.PARAMETER EnableContextMenus
    When present, causes the installer to configure the Explorer context menus

.EXAMPLE
    Install-VSCode.ps1 -Architecture 32-bit

    Installs Visual Studio Code (32-bit) and the powershell extension.
.EXAMPLE
    Install-VSCode.ps1 -LaunchWhenDone

    Installs Visual Studio Code (64-bit) and the PowerShell extension and then launches
    the editor after installation completes.

.EXAMPLE
    Install-VSCode.ps1 -AdditionalExtensions 'eamodio.gitlens', 'vscodevim.vim'

    Installs Visual Studio Code (64-bit), the PowerShell extension, and additional
    extensions.

.EXAMPLE
    Install-VSCode.ps1 -BuildEdition Insider-User -LaunchWhenDone

    Installs Visual Studio Code Insiders Edition (64-bit) to the user profile and then launches the editor
    after installation completes.

.NOTES
    This script is licensed under the MIT License:

    Copyright (c) Microsoft Corporation.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter()]
    [ValidateSet('64-bit', '32-bit')]
    [string]$Architecture = '64-bit',

    [parameter()]
    [ValidateSet('Stable-System', 'Stable-User', 'Insider-System', 'Insider-User')]
    [string]$BuildEdition = "Stable-System",

    [Parameter()]
    [ValidateNotNull()]
    [string[]]$AdditionalExtensions = @(),

    [switch]$LaunchWhenDone,

    [switch]$EnableContextMenus
)

# Taken from https://code.visualstudio.com/docs/setup/linux#_installation
$script:VSCodeYumRepoEntry = @"
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
"@

$script:VSCodeZypperRepoEntry = @"
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
"@

function Test-IsOsArchX64 {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture -match '64'
    }

    return [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::X64
}

function Get-AvailablePackageManager
{
    if (Get-Command 'apt' -ErrorAction SilentlyContinue) {
        return 'apt'
    }

    if (Get-Command 'dnf' -ErrorAction SilentlyContinue) {
        return 'dnf'
    }

    if (Get-Command 'yum' -ErrorAction SilentlyContinue) {
        return 'yum'
    }

    if (Get-Command 'zypper' -ErrorAction SilentlyContinue) {
        return 'zypper'
    }
}

function Get-CodePlatformInformation {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('32-bit', '64-bit')]
        [string]
        $Bitness,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Stable-System', 'Stable-User', 'Insider-System', 'Insider-User')]
        [string]
        $BuildEdition
    )

    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        $os = 'Windows'
    }
    elseif ($IsLinux) {
        $os = 'Linux'
    }
    elseif ($IsMacOS) {
        $os = 'MacOS'
    }
    else {
        throw 'Could not identify operating system'
    }

    if ($Bitness -ne '64-bit' -and $os -ne 'Windows') {
        throw "Non-64-bit *nix systems are not supported"
    }

    if ($BuildEdition.EndsWith('User') -and $os -ne 'Windows') {
        throw 'User builds are not available for non-Windows systems'
    }

    switch ($BuildEdition) {
        'Stable-System' {
            $appName = "Visual Studio Code ($Bitness)"
            break
        }

        'Stable-User' {
            $appName = "Visual Studio Code ($($Architecture) - User)"
            break
        }

        'Insider-System' {
            $appName = "Visual Studio Code - Insiders Edition ($Bitness)"
            break
        }

        'Insider-User' {
            $appName = "Visual Studio Code - Insiders Edition ($($Architecture) - User)"
            break
        }
    }

    switch ($os) {
        'Linux' {
            $pacMan = Get-AvailablePackageManager

            switch ($pacMan) {
                'apt' {
                    $platform = 'linux-deb-x64'
                    $ext = 'deb'
                    break
                }

                { 'dnf','yum','zypper' -contains $_ } {
                    $platform = 'linux-rpm-x64'
                    $ext = 'rpm'
                    break
                }

                default {
                    $platform = 'linux-x64'
                    $ext = 'tar.gz'
                    break
                }
            }

            if ($BuildEdition.StartsWith('Insider')) {
                $exePath = '/usr/bin/code-insiders'
                break
            }

            $exePath = '/usr/bin/code'
            break
        }

        'MacOS' {
            $platform = 'darwin'
            $ext = 'zip'

            if ($BuildEdition.StartsWith('Insider')) {
                $exePath = '/usr/local/bin/code-insiders'
                break
            }

            $exePath = '/usr/local/bin/code'
            break
        }

        'Windows' {
            $ext = 'exe'
            switch ($Bitness) {
                '32-bit' {
                    $platform = 'win32'

                    if (Test-IsOsArchX64) {
                        $installBase = ${env:ProgramFiles(x86)}
                        break
                    }

                    $installBase = ${env:ProgramFiles}
                    break
                }

                '64-bit' {
                    $installBase = ${env:ProgramFiles}

                    if (Test-IsOsArchX64) {
                        $platform = 'win32-x64'
                        break
                    }

                    Write-Warning '64-bit install requested on 32-bit system. Installing 32-bit VSCode'
                    $platform = 'win32'
                    break
                }
            }

            switch ($BuildEdition) {
                'Stable-System' {
                    $exePath = "$installBase\Microsoft VS Code\bin\code.cmd"
                }

                'Stable-User' {
                    $exePath = "${env:LocalAppData}\Programs\Microsoft VS Code\bin\code.cmd"
                }

                'Insider-System' {
                    $exePath = "$installBase\Microsoft VS Code Insiders\bin\code-insiders.cmd"
                }

                'Insider-User' {
                    $exePath = "${env:LocalAppData}\Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd"
                }
            }
        }
    }

    switch ($BuildEdition) {
        'Stable-System' {
            $channel = 'stable'
            break
        }

        'Stable-User' {
            $channel = 'stable'
            $platform += '-user'
            break
        }

        'Insider-System' {
            $channel = 'insider'
            break
        }

        'Insider-User' {
            $channel = 'insider'
            $platform += '-user'
            break
        }
    }

    $info = @{
        AppName = $appName
        ExePath = $exePath
        Platform = $platform
        Channel = $channel
        FileUri = "https://update.code.visualstudio.com/latest/$platform/$channel"
        Extension = $ext
    }

    if ($pacMan) {
        $info['PackageManager'] = $pacMan
    }

    return $info
}

function Save-WithBitsTransfer {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $FileUri,

        [Parameter(Mandatory=$true)]
        [string]
        $Destination,

        [Parameter(Mandatory=$true)]
        [string]
        $AppName
    )

    Write-Host "`nDownloading latest $AppName..." -ForegroundColor Yellow

    Remove-Item -Force $Destination -ErrorAction SilentlyContinue

    $bitsDl = Start-BitsTransfer $FileUri -Destination $Destination -Asynchronous

    while (($bitsDL.JobState -eq 'Transferring') -or ($bitsDL.JobState -eq 'Connecting')) {
        Write-Progress -Activity "Downloading: $AppName" -Status "$([math]::round($bitsDl.BytesTransferred / 1mb))mb / $([math]::round($bitsDl.BytesTotal / 1mb))mb" -PercentComplete ($($bitsDl.BytesTransferred) / $($bitsDl.BytesTotal) * 100 )
    }

    switch ($bitsDl.JobState) {

        'Transferred' {
            Complete-BitsTransfer -BitsJob $bitsDl
            break
        }

        'Error' {
            throw 'Error downloading installation media.'
        }
    }
}

function Install-VSCodeFromTar {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $TarPath,

        [Parameter()]
        [switch]
        $Insiders
    )

    $tarDir = Join-Path ([System.IO.Path]::GetTempPath()) 'VSCodeTar'
    $destDir = '/opt/VSCode-linux-x64'

    New-Item -ItemType Directory -Force -Path $tarDir
    try {
        Push-Location $tarDir
        tar xf $TarPath
        Move-Item -LiteralPath "$tarDir/VSCode-linux-x64" $destDir
    }
    finally {
        Pop-Location
    }

    if ($Insiders) {
        ln -s "$destDir/code-insiders" /usr/bin/code-insiders
        return
    }

    ln -s "$destDir/code" /usr/bin/code
}

# We need to be running as elevated on *nix
if (($IsLinux -or $IsMacOS) -and (id -u) -ne 0) {
    throw "Must be running as root to install VSCode.`nInvoke this script with (for example):`n`tsudo pwsh -f Install-VSCode.ps1 -BuildEdition Stable-System"
}

# User builds can only be installed on Windows systems
if ($BuildEdition.EndsWith('User') -and -not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
    throw 'User builds are not available for non-Windows systems'
}

try {
    $prevProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    # Get information required for installation
    $codePlatformInfo = Get-CodePlatformInformation -Bitness $Architecture -BuildEdition $BuildEdition

    # Download the installer
    $tmpdir = [System.IO.Path]::GetTempPath()

    $ext = $codePlatformInfo.Extension
    $installerName = "vscode-install.$ext"

    $installerPath = [System.IO.Path]::Combine($tmpdir, $installerName)

    if ($PSVersionTable.PSVersion.Major -le 5) {
        Save-WithBitsTransfer -FileUri $codePlatformInfo.FileUri -Destination $installerPath -AppName $codePlatformInfo.AppName
    }
    # We don't want to use RPM packages -- see the installation step below
    elseif ($codePlatformInfo.Extension -ne 'rpm') {
        if ($PSCmdlet.ShouldProcess($codePlatformInfo.FileUri, "Invoke-WebRequest -OutFile $installerPath")) {
            Invoke-WebRequest -Uri $codePlatformInfo.FileUri -OutFile $installerPath
        }
    }

    # Install VSCode
    switch ($codePlatformInfo.Extension) {
        # On Debian-like Linux distros
        'deb' {
            if (-not $PSCmdlet.ShouldProcess($installerPath, 'apt install -y')) {
                break
            }

            # The deb file contains the information to install its own repository,
            # so we just need to install it
            apt install -y $installerPath
            break
        }

        # On distros using rpm packages, the RPM package doesn't set up the repo.
        # To install VSCode properly in way that the package manager tracks it,
        # we have to do things the hard way - install the repo and install the package
        'rpm' {
            $pacMan = $codePlatformInfo.PackageManager
            if (-not $PSCmdlet.ShouldProcess($installerPath, "$pacMan install -y")) {
                break
            }

            # Install the VSCode repo with the package manager
            rpm --import https://packages.microsoft.com/keys/microsoft.asc

            switch ($pacMan) {
                'zypper' {
                    $script:VSCodeZypperRepoEntry > /etc/zypp/repos.d/vscode.repo
                    zypper refresh -y
                }

                default {
                    $script:VSCodeYumRepoEntry > /etc/yum.repos.d/vscode.repo
                    & $pacMan check-update -y
                }
            }

            switch ($BuildEdition) {
                'Stable-System' {
                    & $pacMan install -y code
                }

                default {
                    & $pacMan install -y code-insiders
                }
            }
            break
        }

        # On Windows
        'exe' {
            $exeArgs = '/verysilent /tasks=addtopath'
            if ($EnableContextMenus) {
                $exeArgs = '/verysilent /tasks=addcontextmenufiles,addcontextmenufolders,addtopath'
            }

            if (-not $PSCmdlet.ShouldProcess("$installerPath $exeArgs", 'Start-Process -Wait')) {
                break
            }

            Start-Process -Wait $installerPath -ArgumentList $exeArgs
            break
        }

        # On Mac
        'zip' {
            if (-not $PSCmdlet.ShouldProcess($installerPath, "Expand-Archive -DestinationPath $zipDirPath -Force; Move-Item $zipDirPath/*.app /Applications/")) {
                break
            }

            $zipDirPath = [System.IO.Path]::Combine($tmpdir, 'VSCode')
            Expand-Archive -LiteralPath $installerPath -DestinationPath $zipDirPath -Force
            Move-Item "$zipDirPath/*.app" '/Applications/'
            break
        }

        # Remaining Linux distros using tar - more complicated
        'tar.gz' {
            if (-not $PSCmdlet.ShouldProcess($installerPath, 'Install-VSCodeFromTar (expand, move to /opt/, symlink)')) {
                break
            }

            Install-VSCodeFromTar -TarPath $installerPath -Insiders:($BuildEdition -ne 'Stable-System')
            break
        }

        default {
            throw "Unkown package type: $($codePlatformInfo.Extension)"
        }
    }

    $codeExePath = $codePlatformInfo.ExePath

    # Install any extensions
    $extensions = @("ms-vscode.PowerShell") + $AdditionalExtensions
    if ($PSCmdlet.ShouldProcess(($extensions -join ','), "$codeExePath --install-extension")) {
        if ($IsLinux -or $IsMacOS) {
            # On *nix we need to install extensions as the user -- VSCode refuses root
            $extsSlashes = $extensions -join '/'
            sudo -H -u $env:SUDO_USER pwsh -c "`$exts = '$extsSlashes' -split '/'; foreach (`$e in `$exts) { $codeExePath --install-extension `$e }"
        }
        else {
            foreach ($extension in $extensions) {
                Write-Host "`nInstalling extension $extension..." -ForegroundColor Yellow
                & $codeExePath --install-extension $extension
            }
        }
    }

    # Launch if requested
    if ($LaunchWhenDone) {
        $appName = $codePlatformInfo.AppName

        if (-not $PSCmdlet.ShouldProcess($appName, "Launch with $codeExePath")) {
            return
        }

        Write-Host "`nInstallation complete, starting $appName...`n`n" -ForegroundColor Green
        & $codeExePath
        return
    }

    if ($PSCmdlet.ShouldProcess('Installation complete!', 'Write-Host')) {
        Write-Host "`nInstallation complete!`n`n" -ForegroundColor Green
    }
}
finally {
    $ProgressPreference = $prevProgressPreference
}

# SIG # Begin signature block
# MIInrgYJKoZIhvcNAQcCoIInnzCCJ5sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCEmTjzkBaLWIc+
# GQjph+Pla7B65qdwGita70sxJbemDaCCDYUwggYDMIID66ADAgECAhMzAAACU+OD
# 3pbexW7MAAAAAAJTMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMzAwWhcNMjIwOTAxMTgzMzAwWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDLhxHwq3OhH+4J+SX4qS/VQG8HybccH7tnG+BUqrXubfGuDFYPZ29uCuHfQlO1
# lygLgMpJ4Geh6/6poQ5VkDKfVssn6aA1PCzIh8iOPMQ9Mju3sLF9Sn+Pzuaie4BN
# rp0MuZLDEXgVYx2WNjmzqcxC7dY9SC3znOh5qUy2vnmWygC7b9kj0d3JrGtjc5q5
# 0WfV3WLXAQHkeRROsJFBZfXFGoSvRljFFUAjU/zdhP92P+1JiRRRikVy/sqIhMDY
# +7tVdzlE2fwnKOv9LShgKeyEevgMl0B1Fq7E2YeBZKF6KlhmYi9CE1350cnTUoU4
# YpQSnZo0YAnaenREDLfFGKTdAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUlZpLWIccXoxessA/DRbe26glhEMw
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzQ2NzU5ODAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AKVY+yKcJVVxf9W2vNkL5ufjOpqcvVOOOdVyjy1dmsO4O8khWhqrecdVZp09adOZ
# 8kcMtQ0U+oKx484Jg11cc4Ck0FyOBnp+YIFbOxYCqzaqMcaRAgy48n1tbz/EFYiF
# zJmMiGnlgWFCStONPvQOBD2y/Ej3qBRnGy9EZS1EDlRN/8l5Rs3HX2lZhd9WuukR
# bUk83U99TPJyo12cU0Mb3n1HJv/JZpwSyqb3O0o4HExVJSkwN1m42fSVIVtXVVSa
# YZiVpv32GoD/dyAS/gyplfR6FI3RnCOomzlycSqoz0zBCPFiCMhVhQ6qn+J0GhgR
# BJvGKizw+5lTfnBFoqKZJDROz+uGDl9tw6JvnVqAZKGrWv/CsYaegaPePFrAVSxA
# yUwOFTkAqtNC8uAee+rv2V5xLw8FfpKJ5yKiMKnCKrIaFQDr5AZ7f2ejGGDf+8Tz
# OiK1AgBvOW3iTEEa/at8Z4+s1CmnEAkAi0cLjB72CJedU1LAswdOCWM2MDIZVo9j
# 0T74OkJLTjPd3WNEyw0rBXTyhlbYQsYt7ElT2l2TTlF5EmpVixGtj4ChNjWoKr9y
# TAqtadd2Ym5FNB792GzwNwa631BPCgBJmcRpFKXt0VEQq7UXVNYBiBRd+x4yvjqq
# 5aF7XC5nXCgjbCk7IXwmOphNuNDNiRq83Ejjnc7mxrJGMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGX8wghl7AgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAJT44Pelt7FbswAAAAA
# AlMwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJRr
# if/9jFWDpmpD1GsnPiCT0db2vU7T7obRPJr4sn+YMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAo3YluaStjfi3EdI1ViQj195QQhI6n6suniQL
# 87DMkwVAmeZi2gitGjSibRaUIapaUFpm/6BULUv7L6kRmWWC1ZX6Px0DuwKpB+FP
# yo6wTRCvUIGa9fvfYAhP/20wX7s/BG3ahKzF6SUUyNydl1TA4BmIMuoKTUVfvrm2
# nNWHLTzHW33XhNaouzn1VEW7wrTAyXp1W/sfZV4pI9caWrG4Uatbqh0bEfiu79vr
# vZGGK/EemqqMJujqpc66QpjeiwLpHeo1XbfHUMJ4/O+JW81jFlusZawcsH6rY1hf
# TdeGOAolk9o/4/Ydckw0Ag0lCCcrXU5BTfnoxAnQvv0bwvaviaGCFwkwghcFBgor
# BgEEAYI3AwMBMYIW9TCCFvEGCSqGSIb3DQEHAqCCFuIwghbeAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFVBgsqhkiG9w0BCRABBKCCAUQEggFAMIIBPAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCBm1Ui9QVzLXFD9qgxGZz65dByPhad/nmUt
# Y+e7DSvgrwIGYrIUqedvGBMyMDIyMDYyOTIxMjEyMS45MDFaMASAAgH0oIHUpIHR
# MIHOMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSkwJwYDVQQL
# EyBNaWNyb3NvZnQgT3BlcmF0aW9ucyBQdWVydG8gUmljbzEmMCQGA1UECxMdVGhh
# bGVzIFRTUyBFU046RDlERS1FMzlBLTQzRkUxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFNlcnZpY2WgghFcMIIHEDCCBPigAwIBAgITMwAAAaxmvIciXd49
# ewABAAABrDANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMDAeFw0yMjAzMDIxODUxMjlaFw0yMzA1MTExODUxMjlaMIHOMQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSkwJwYDVQQLEyBNaWNyb3NvZnQg
# T3BlcmF0aW9ucyBQdWVydG8gUmljbzEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046
# RDlERS1FMzlBLTQzRkUxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2UwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDHeAtQxRdi7sdx
# zCvABJTHUxeIhvUTsikFhXoU13vhF9UDq0wRZ4TACjRyEFqMZCtVutv6EEEJrSB6
# PLKYTLdVqZCzbwpty2vLHVS97fwQMe1FpJn77oydyg2koLd3JXObjT1I+3t9lOJ/
# xKfaDnPj7/xB3O1xh9Xxkby0WM8KMT9cZCpXrrGyM0/2ip+lgtgYID84x14p/ShO
# 5K4grqgPiTYbJJHnUxyUCKLW5Ufq2XLHsU0pozvme0dJn3h4lPA57b2b2f/WnfV1
# IQ8FCRSmfGWb8Z6p2V8BWJAyjWoGPINOgRdbw7pW5QLOgOIbj9Xu6bShaaQdVWZC
# 1AJiFtccSRrN5HonQE1iFcdtrBlcnpmk9vTX7Q6f40bA8P2ocL9TZL+lr8pKLytJ
# AzyGPUwlvXEW71HhJZPvglTO3CKq5fEGN5oBEPKIuOVcxAV7mNOGNSoo2xi2ERTV
# MqVzEQwKVfpHIxvLkk9d5kgn9ojIVkUS8/f48iMHu5Zl8+M1MmHJK/tjZvBq0quX
# 1QD7ISDvAG/2jqOv6Htxt2PnIpfIskSSyTcWzGMYkCSmb28ZQiKfqRiJ2g9d+9zO
# yjzxf8l3k+IRtC6lyr3pZILZac3nz65lFbqY2E4Hhn7qVMBc8pkpOCUTTtbYUQdG
# wygyMjTFahLr1dVMXXK4nFdKI4HiRwIDAQABo4IBNjCCATIwHQYDVR0OBBYEFFgR
# n3cEyx9AZ0o8fElamFrAQI5NMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1
# GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEp
# LmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUy
# MFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYB
# BQUHAwgwDQYJKoZIhvcNAQELBQADggIBAHnQtQJYVVxwpXZPLaCMwFvUMiE3EXso
# VKbNbg+u8wgt9PH0c2BREv9rzF+6NDmyYMwsU9Z4tL5HLPFhtjFCLJPdUQjyHg80
# 0CLSKY/WU8/YdLbn3Chpt2oZJ0bNYaFddo0RZHGqlyaNX7MrqCoA/hU09pTr6xLD
# YyYecBLIvjwf5lZofyWtFbvI4VCXNYawVEOWIrEODdNLJ2cITqAnj123Q+hxrNXJ
# rF2W65E/LzT2FfC5yOJcbif2GmEttKkK+mPQyBxQzWMWW05bEHl7Pyo54UTXRYgh
# qAHCx1sHlnkbM4dolITH2Nf+/Xe7KJn48emciT2Tq+HxNFE9pf6wWgU66D6Qzr6W
# jrGOhP7XiyzH8p6+lDkHhOJUYsOfbIlRsgBqqUwU23cwBSwRR+NLm6+1RJXZo4h2
# teBJGcWL3IMysSqrm+Mqymn6P4/WlG8C6y9lTB1nKWtfCYb+syI3dNSBpFHY91Cf
# iSkDQM+Xsj8kEmT7fcLPG8p6HRpTOZ2JBwcu6z74+Ocvmc+46y4I4L2SIsRrM8Ki
# siieOwDx8ax/BowkLrG71vTReCwGCqGWRo+z8JkAPl5sA+bX1ENCrszERZjKTlM7
# YkwICY0H/UzLnN6WJqRVhK/JLGHcK463VmACwlwPyEFxHQIrEMI+WM07IeEMU1Kv
# r0UsbPd8gd5yMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+
# F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU
# 88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqY
# O7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzp
# cGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0Xn
# Rm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1
# zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZN
# N3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLR
# vWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTY
# uVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUX
# k8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB
# 2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKR
# PEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0g
# BFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQM
# MAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQ
# W9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNv
# bS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBa
# BggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqG
# SIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOX
# PTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6c
# qYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/z
# jj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz
# /AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyR
# gNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdU
# bZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo
# 3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4K
# u+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10Cga
# iQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9
# vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGC
# As8wggI4AgEBMIH8oYHUpIHRMIHOMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSkwJwYDVQQLEyBNaWNyb3NvZnQgT3BlcmF0aW9ucyBQdWVydG8g
# UmljbzEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RDlERS1FMzlBLTQzRkUxJTAj
# BgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMC
# GgMVALEa0hOwuLBJ/egDIYzZF2dGNYqgoIGDMIGApH4wfDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQACBQDmZx68MCIYDzIwMjIwNjI5
# MjI1NTU2WhgPMjAyMjA2MzAyMjU1NTZaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIF
# AOZnHrwCAQAwBwIBAAICFq0wBwIBAAICERkwCgIFAOZocDwCAQAwNgYKKwYBBAGE
# WQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDAN
# BgkqhkiG9w0BAQUFAAOBgQAuLEfvKMLDjtfbnj0iSoAXMde1lGQXVGw5NtbCCnZk
# Z1NMEYpTEjEYbdRvfmT09t+0Sg0ywLsNGMrCZBBT3C/WUYfrCfAH+9hltuFP3eKe
# 6s+y5gpiynpcXZpwtd1oMIsMVUpZ0F5lxLVJ2g1Ay0t/QL4sss/MijkXbMJa8ZA3
# LTGCBA0wggQJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAABrGa8hyJd3j17AAEAAAGsMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0B
# CQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIN1PgvTJ9xxwm5FFKftI
# W8BH+w0dpvU1VeOYqERLD9seMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg
# +bcBkoM4LwlxAHK1c+epu/T6fm0CX/tPi4Nn2gQswvUwgZgwgYCkfjB8MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAaxmvIciXd49ewABAAABrDAiBCAA
# cwEn58duG4txig9LDrwJpCXRSvxFG84ljSshf2FO/zANBgkqhkiG9w0BAQsFAASC
# AgAqyiZi6UmDUp1v9czZP3xjWacidXpsZq/ZNL6a1SO2UrkV/6/ihLltMNOIGSC6
# d4aW8aLD769eL4Q5IKrga/MfwKuheZ73w2gPCn5H0lvN4IDvCZ0h6EUCa3IxlLkf
# vOhA2/+gScsooa1eHfYJXHDnreMLYpB1ZE2y0no3ctEqfYuGOK3qwYKzeodFrPo+
# ZNGl40OzpA9mcFAdxYCsmb/sawHp6lP4sD919EHCeG3IWRJz3WZbQV4b3LXLBFFh
# 9aW1YvSdT9G3rv98jF/d1Vwm/OuuYh4amkCcuK3lCbkkviItYN5GO2LHJN+ovvoG
# btdoPyk357RSuUde+976zfCvwtiR72AcfaTnsmO71dfB06Ggbs9JsG1g0Zt+aOwj
# /STkZm9gXE9muYThqG259+LX3iLEAMHbxH122AXTcgBdbLrmoUjKOw+k+enhPoB6
# 3aBMNgbILAAZU8bTIcWHibsla7pj56m6lWLT2iMqEShB0IXTuf7qX5bd9t3QfzPC
# t3J3bArQldXzgzdjpQH9mUSQSc7yvzvXA3qsieqYXs3QGPf4Kb9ACH3T/xoYt+Y5
# COQYmUFcDaxNX09tc4DUXxkdhuQwYoBPaI1UIX3e8qsDqtlhHXRIVPwt/9XmWXOw
# Zi/KPSz8dKiHzp6i59n5ksBtxsaYnGg72Npt+N+Yrx57iw==
# SIG # End signature block
