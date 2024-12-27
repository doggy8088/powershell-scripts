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

# SIG # Begin signature block
# MIISOQYJKoZIhvcNAQcCoIISKjCCEiYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCLCt6eSP83+jRA
# qyIAIFWU6GRM3txZO+sZAgJRMfJxoKCCDnEwggboMIIE0KADAgECAhB3vQ4Ft1kL
# th1HYVMeP3XtMA0GCSqGSIb3DQEBCwUAMFMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENvZGUgU2ln
# bmluZyBSb290IFI0NTAeFw0yMDA3MjgwMDAwMDBaFw0zMDA3MjgwMDAwMDBaMFwx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTIwMAYDVQQD
# EylHbG9iYWxTaWduIEdDQyBSNDUgRVYgQ29kZVNpZ25pbmcgQ0EgMjAyMDCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMsg75ceuQEyQ6BbqYoj/SBerjgS
# i8os1P9B2BpV1BlTt/2jF+d6OVzA984Ro/ml7QH6tbqT76+T3PjisxlMg7BKRFAE
# eIQQaqTWlpCOgfh8qy+1o1cz0lh7lA5tD6WRJiqzg09ysYp7ZJLQ8LRVX5YLEeWa
# tSyyEc8lG31RK5gfSaNf+BOeNbgDAtqkEy+FSu/EL3AOwdTMMxLsvUCV0xHK5s2z
# BZzIU+tS13hMUQGSgt4T8weOdLqEgJ/SpBUO6K/r94n233Hw0b6nskEzIHXMsdXt
# HQcZxOsmd/KrbReTSam35sOQnMa47MzJe5pexcUkk2NvfhCLYc+YVaMkoog28vmf
# vpMusgafJsAMAVYS4bKKnw4e3JiLLs/a4ok0ph8moKiueG3soYgVPMLq7rfYrWGl
# r3A2onmO3A1zwPHkLKuU7FgGOTZI1jta6CLOdA6vLPEV2tG0leis1Ult5a/dm2tj
# IF2OfjuyQ9hiOpTlzbSYszcZJBJyc6sEsAnchebUIgTvQCodLm3HadNutwFsDeCX
# pxbmJouI9wNEhl9iZ0y1pzeoVdwDNoxuz202JvEOj7A9ccDhMqeC5LYyAjIwfLWT
# yCH9PIjmaWP47nXJi8Kr77o6/elev7YR8b7wPcoyPm593g9+m5XEEofnGrhO7izB
# 36Fl6CSDySrC/blTAgMBAAGjggGtMIIBqTAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUJZ3Q
# /FkJhmPF7POxEztXHAOSNhEwHwYDVR0jBBgwFoAUHwC/RoAK/Hg5t6W0Q9lWULvO
# ljswgZMGCCsGAQUFBwEBBIGGMIGDMDkGCCsGAQUFBzABhi1odHRwOi8vb2NzcC5n
# bG9iYWxzaWduLmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUwRgYIKwYBBQUHMAKGOmh0
# dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2NvZGVzaWduaW5ncm9v
# dHI0NS5jcnQwQQYDVR0fBDowODA2oDSgMoYwaHR0cDovL2NybC5nbG9iYWxzaWdu
# LmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3JsMFUGA1UdIAROMEwwQQYJKwYBBAGg
# MgECMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3Jl
# cG9zaXRvcnkvMAcGBWeBDAEDMA0GCSqGSIb3DQEBCwUAA4ICAQAldaAJyTm6t6E5
# iS8Yn6vW6x1L6JR8DQdomxyd73G2F2prAk+zP4ZFh8xlm0zjWAYCImbVYQLFY4/U
# ovG2XiULd5bpzXFAM4gp7O7zom28TbU+BkvJczPKCBQtPUzosLp1pnQtpFg6bBNJ
# +KUVChSWhbFqaDQlQq+WVvQQ+iR98StywRbha+vmqZjHPlr00Bid/XSXhndGKj0j
# fShziq7vKxuav2xTpxSePIdxwF6OyPvTKpIz6ldNXgdeysEYrIEtGiH6bs+XYXvf
# cXo6ymP31TBENzL+u0OF3Lr8psozGSt3bdvLBfB+X3Uuora/Nao2Y8nOZNm9/Lws
# 80lWAMgSK8YnuzevV+/Ezx4pxPTiLc4qYc9X7fUKQOL1GNYe6ZAvytOHX5OKSBoR
# HeU3hZ8uZmKaXoFOlaxVV0PcU4slfjxhD4oLuvU/pteO9wRWXiG7n9dqcYC/lt5y
# A9jYIivzJxZPOOhRQAyuku++PX33gMZMNleElaeEFUgwDlInCI2Oor0ixxnJpsoO
# qHo222q6YV8RJJWk4o5o7hmpSZle0LQ0vdb5QMcQlzFSOTUpEYck08T7qWPLd0jV
# +mL8JOAEek7Q5G7ezp44UCb0IXFl1wkl1MkHAHq4x/N36MXU4lXQ0x72f1LiSY25
# EXIMiEQmM2YBRN/kMw4h3mKJSAfa9TCCB4EwggVpoAMCAQICDGLH+ed0mpc2dVMr
# hzANBgkqhkiG9w0BAQsFADBcMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2lnbiBHQ0MgUjQ1IEVWIENvZGVT
# aWduaW5nIENBIDIwMjAwHhcNMjMxMjEzMDYwODI2WhcNMjUwMTE5MDY0NTAxWjCB
# 5jEdMBsGA1UEDwwUUHJpdmF0ZSBPcmdhbml6YXRpb24xETAPBgNVBAUTCDEyNjk0
# MjcyMRMwEQYLKwYBBAGCNzwCAQMTAlRXMQswCQYDVQQGEwJUVzEPMA0GA1UECBMG
# VGFpcGVpMQ8wDQYDVQQHEwZUYWlwZWkxQDA+BgNVBAkTNzcgRi4sIE5vLiA4Miwg
# U2VjLiAxLCBaaG9uZ3NoYW4gTi4gUmQuLCBaaG9uZ3NoYW4gRGlzdC4xFTATBgNV
# BAoTDER1b3RpZnkgSW5jLjEVMBMGA1UEAxMMRHVvdGlmeSBJbmMuMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtHvxgWTRtj4CACDb6YfB5zz9eyvPXTDk
# LSQtlKm7SajYjl1ta+XUF40u4WfPakCSMaf3/KlUMERI+FIJSbKQRRuKOq+56P8M
# 9g1hooZqTjoSt+ZJmKVEBY6NYboKCnJvVk39iQv9YrmmIv4DvQIjAyvX8cWlz1No
# zk9SqZ1/eu4x0jFRmKua5Q50Kk4yI70GDPPidl0lHaq/gSgk6EG93Jtmk4BGyG/X
# fprm/SKTm1lUSQmpyWjStsTXqaXyccYEzGXu6VA7grlPSkkP+R8Zuf7KpzRpqHzt
# Y4O6Gx48qiF/IPa7Gh/EkZLKvLepGrBwjk/azuZf2sSDQDHrO5K4WFwLt18vA6u+
# Qa/EMTpBTb6RJEfwPtDZnj9ldU+/aiLE1LmiL7Kuo6/Df+mEHc2L2wmqqqNG3aIC
# V487lSmTf2C7ctVNvXVXgUP1rDv7kOOxzxRZdkttu/TEv9Ixfxg3lQXZeAIB4bcX
# Ato4sNcDQtU9phh7DFuDh1L+xdfoF3b24jfp93Mnl1KjebYZhchgOs1XlbAtGsKl
# EBckQLQ7kmwP/+teGVKB8hS/XqtEHjpZD61Y4SeiwyInS5k9BaSxKkSbF03dpW2W
# M8txUce1Znu9TiUHFt6KAEAbGauMl9+CE6q3HbJnXmOTMO8fQ6Dl+6/RqC9qWOLn
# uHF2jXDfsU0CAwEAAaOCAbYwggGyMA4GA1UdDwEB/wQEAwIHgDCBnwYIKwYBBQUH
# AQEEgZIwgY8wTAYIKwYBBQUHMAKGQGh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5j
# b20vY2FjZXJ0L2dzZ2NjcjQ1ZXZjb2Rlc2lnbmNhMjAyMC5jcnQwPwYIKwYBBQUH
# MAGGM2h0dHA6Ly9vY3NwLmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1ZXZjb2Rlc2ln
# bmNhMjAyMDBVBgNVHSAETjBMMEEGCSsGAQQBoDIBAjA0MDIGCCsGAQUFBwIBFiZo
# dHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAHBgVngQwBAzAJ
# BgNVHRMEAjAAMEcGA1UdHwRAMD4wPKA6oDiGNmh0dHA6Ly9jcmwuZ2xvYmFsc2ln
# bi5jb20vZ3NnY2NyNDVldmNvZGVzaWduY2EyMDIwLmNybDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAfBgNVHSMEGDAWgBQlndD8WQmGY8Xs87ETO1ccA5I2ETAdBgNVHQ4E
# FgQU3twvvzr2BrsSCfr22cn+y85mjZ4wDQYJKoZIhvcNAQELBQADggIBAGys9QMx
# pRUB272UOxBz8RUziTYroj1KIgGBEEBUiVRZzhUkbYkWELL5Kd956+RTN584QodE
# ra2LRcyJWLs9lajLxCCBCcrT8B7UXeaN3eANcMbkuatw+Ehc9X675Wx9FBgX4oiq
# g2bQbgGvn7I+HG8vaHKO7gVZ/7iRxfLgzAbNKnqw6rKAyx5dzdTBMXvcmwjCA3Hc
# aAuCJt4ddOQJIZrPKAJ1QvZhdEuj/wJe1y4m102v/8Kl4XEXO8z+eXTialAYMyUp
# 9FhR8i3nROK3SufU5F6FijtKqKVWYehRB17HOpXZ1VHnRmq0M6Ahyrm5CJrn04Il
# zdTsLk6VutELh1JfYrTM0P2rQzD/tiPsnPS4uETzDfv2VJXjv7lTIxvH4Kk8Xp+r
# FsMj3qCy+YBvNDLFr6QxqqrYaOwcE2Iwh2wENZZmsNuo2rsxeWVDMjCqkht/YBO1
# hVgX9MyZpM/j85xHFIlx5T9PVUxOFRkugHUpRZo6P7mfTEVZgVfDtXp5gmoy/nVE
# SuDmclopO4N9b4ajOtkV3+A1lWV7ugR3JS/yskFJKuIkihh8ugsXo9wOnxHvgGvI
# JGvrhmqkc4LeALjNnN8W5hnkxdwDN+32s/e6lGGUXGABxkvmleiNdZ8mvDF8xQZ+
# XsWy1CiOhbIQTGDuxJfqmqdHyrlOP+9amcyqMYIDHjCCAxoCAQEwbDBcMQswCQYD
# VQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEyMDAGA1UEAxMpR2xv
# YmFsU2lnbiBHQ0MgUjQ1IEVWIENvZGVTaWduaW5nIENBIDIwMjACDGLH+ed0mpc2
# dVMrhzANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAA
# MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
# BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCB7pdb8xLYkLSJeqS76gCDDWk7Ac82V
# To5mgxKg7CpUOzANBgkqhkiG9w0BAQEFAASCAgBCqUGq3ZlOGRS6n9K7KB6coG65
# 7uj+3IIQZDjVbLqmdbO3eeta46AIegul6SNDj3MFOU3c24a4VFMPIg0rg3N/Nn1K
# XoiPUJjrsOgqYgSuGL36E+/+YdtZC+L8wKpz3ewY4wWenTzTG2liZGEgo3Qn184x
# CDsD56PfqYLuPOHxZ5Gbr1uSFhMh9ebS8x7EPjz1ALrpKopxrhrKGy746Io6RXN+
# RbKEUp0DDtVxNFpD3nwy0CLr2jz5cq5mKctAPKaTrlhZ/SL68IbXb44/uiXmFSmt
# DVmgXDzBz3Yqg6rl53sssWD6ftxEt8J1PwMxmwzM7aJVnSALS/xuLl+2Ryrqtoko
# nREeMHNlWmIZ1wUoK2IFIiRqB5Z8cTfVi+Xnr5MdyQGivRWJGi4xWE8HfDHScWXZ
# uxcR1kQV5plx7oOb13e8seD2jc3orBZPE9Vp1HXv5rxFj42BvQZNPBi04UjSNVqA
# VQe5C5wgi3PjQZTs9bYLnbdwYmp3OQv9lI66YbRu4mNSVfF5S34DKBLXFjvxbgPA
# 1opYNHvbAzFby9oyt+mWy+nsG4aqF/NtfAP7voio28mCxinMuauNz0v3fUbecax0
# ms/k52e0ddhJlc/WGTUVDiy30/nntoRTu7FfFxKAP47i/IKZa9ZXGQN7/VzI52Ge
# l1yhQDNDZZQG8Domkg==
# SIG # End signature block
