<#PSScriptInfo

.VERSION 1.0.0

.GUID f92f765a-0575-4d6d-85a4-c8bd956cc065

.AUTHOR Will Huang

.COMPANYNAME Duotify Inc.

.COPYRIGHT Copyright (c) 2024 Will 保哥

.TAGS install windows terminal canary

.LICENSEURI https://opensource.org/licenses/MIT

.PROJECTURI https://github.com/doggy8088/powershell-scripts

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    2024/12/28 - Initial release.
#>

<#
.SYNOPSIS
    安裝或更新 Windows Terminal Canary 版本。

.DESCRIPTION
    此腳本用於安裝或更新 Windows Terminal Canary 版本。它會檢查目前安裝的版本，並與線上最新版本進行比較。如果有新版本，則會下載並安裝。

.PARAMETER None
    此腳本不需要任何參數。

.EXAMPLE
    Install-WTCanary.ps1

    執行腳本以安裝或更新 Windows Terminal Canary 版本。

.NOTES
    此腳本依賴於 Appx 模組來查詢目前安裝的 Windows Terminal Canary 版本。
#>

# 放在 "$env:USERPROFILE\Documents\PowerShell\Scripts" 的腳本預設就在 PATH 路徑中
# 所以 "Install-WTCanary.ps1" 放在該目錄中後，直接執行 Install-WTCanary 就能跑！

# 查詢目前安裝的版本
Write-Host "正在匯入 Appx 模組..."
Import-Module Appx -UseWindowsPowerShell -WarningAction Ignore
# 1.23.3582.0
$currentVersion = (Get-AppxPackage -Name Microsoft.WindowsTerminalCanary).Version
Write-Host "目前安裝的 Windows Terminal Canary 版本: $currentVersion"

# 下載來源網址（Windows Terminal Canary 的安裝檔 .appinstaller）
$url = "https://aka.ms/terminal-canary-installer"
Write-Host "下載來源網址: $url"

# 決定下載後儲存的目標位置（以下示範放到使用者下載資料夾）
$installerPath = Join-Path $env:TEMP "Microsoft.WindowsTerminalCanary.appinstaller"
Write-Host "儲存下載檔案: $installerPath"

Write-Host "開始下載檔案..."
Invoke-WebRequest -Uri $url -OutFile $installerPath
Write-Host "檔案下載完成。"

# 讀取 XML 檔案內容
Write-Host "讀取 XML 檔案內容..."
[xml]$xmlContent = Get-Content -Path $installerPath

# 檢查是否存在 MainPackage 元素
if ($xmlContent.AppInstaller.MainPackage) {
    Write-Host "檢查 XML 檔案中的 MainPackage 元素..."
    $version = $xmlContent.AppInstaller.MainPackage.Version
    Write-Host "找到 MainPackage 元素，版本為: $version"
}
# 如果不存在，檢查是否存在 MainBundle 元素
elseif ($xmlContent.AppInstaller.MainBundle) {
    Write-Host "檢查 XML 檔案中的 MainBundle 元素..."
    $version = $xmlContent.AppInstaller.MainBundle.Version
    Write-Host "找到 MainBundle 元素，版本為: $version"
}
else {
    Write-Output '未找到 MainPackage 或 MainBundle 元素。'
}

# 輸出版本資訊
if ($version) {
    # 3001.23.3582.0
    Write-Output "目前線上的 Windows Terminal Canary 的版本為：$version"
}

# 如果 $currentVersion 的內容有一部分完全符合 $version，則不進行安裝
if ($version -like "*$currentVersion*") {
    Write-Host "已安裝最新版本，無需更新。刪除 $installerPath..."
    # Remove-Item -Path $installerPath
    Write-Host "刪除 $installerPath 完成。"
    return
}

Write-Host "下載完成，執行安裝程式..."
Start-Process $installerPath
