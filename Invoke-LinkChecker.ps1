<#PSScriptInfo

.VERSION 1.0.0

.GUID 4af1455f-a896-4209-a17c-b8750b80859c

.AUTHOR Will 保哥

.COMPANYNAME Duotify Inc.

.COPYRIGHT Copyright (c) 2023 Will 保哥

.TAGS PowerShell, LinkChecker

.LICENSEURI https://choosealicense.com/licenses/mit/

.PROJECTURI https://github.com/doggy8088/Invoke-LinkChecker-PS1

.ICONURI https://github.com/doggy8088/Learn-Git-in-30-days/assets/88981/5b488410-c647-433d-9135-fbd409a11254

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Initial release

.PRIVATEDATA

#>

<#

.DESCRIPTION
 一個用於執行 linkchecker 命令的 PowerShell 函式，使用指定的參數。

.SYNOPSIS
    一個用於執行 linkchecker 命令的 PowerShell 函式，使用指定的參數。

.PARAMETER Url
    要檢查的 URL。

.PARAMETER Config
    使用 FILENAME 作為配置文件。

.PARAMETER Threads
    生成不超過給定數量的執行緒。

.PARAMETER Version
    顯示版本並退出。

.PARAMETER ListPlugins
    顯示可用的檢查外掛並退出。

# .PARAMETER Stdin
#     從 stdin 讀取空格分隔的要檢查的 URL 列表。

.PARAMETER DebugLogger
    為給定的記錄器偵錯輸出。選項：'cmdline'，'checking'，'cache'，'thread'，'plugin'，'all'。

.PARAMETER FileOutput
    輸出到文件 linkchecker-out.TYPE，$XDG_DATA_HOME/linkchecker/failures 用於 'failures' 輸出，或者指定的 FILENAME。

.PARAMETER NoStatus
    不顯示檢查狀態訊息。

.PARAMETER NoWarnings
    不記錄警告。

.PARAMETER Output
    指定輸出格式為 'csv'，'xml'，'dot'，'failures'，'gml'，'gxml'，'html'，'none'，'sitemap'，'sql'，'text'。

.PARAMETER Quiet
    靜音操作，'-o none' 的別名。

.PARAMETER LogAll
    記錄所有 URL。

.PARAMETER CookieFile
    讀取包含初始 cookie 資料的文件。

.PARAMETER NoRobots
    禁用 robots.txt 檢查。

.PARAMETER CheckExtern
    檢查外部 URL。

.PARAMETER IgnoreUrl
    只檢查與給定正則表達式匹配的 URL 的語法。

.PARAMETER NoFollowUrl
    檢查但不遞迴進入與給定正則表達式匹配的 URL。

.PARAMETER Password
    從控制台讀取密碼並用於 HTTP 和 FTP 授權。

.PARAMETER RecursionLevel
    遞迴檢查所有連結，直至給定深度。

.PARAMETER Timeout
    設定連接嘗試的超時時間（秒）。

.PARAMETER User
    嘗試用於 HTTP 和 FTP 授權的給定用戶名。

.PARAMETER UserAgent
    指定要發送到 HTTP 伺服器的 User-Agent 字串。

.EXAMPLE
    Invoke-LinkChecker -Url "https://example.com" -v -NoRobots
#>
[CmdletBinding()]
param (
    [Parameter(HelpMessage = "要檢查的 URL。")]
    [string]$Url,

    [Parameter(HelpMessage = "使用 FILENAME 作為配置文件。")]
    [string]$Config,

    [Parameter(HelpMessage = "生成不超過給定數量的執行緒。")]
    [int]$Threads,

    [Parameter(HelpMessage = "顯示版本並退出。")]
    [switch]$Version,

    [Parameter(HelpMessage = "顯示可用的檢查外掛並退出。")]
    [switch]$ListPlugins,

    # [Parameter(HelpMessage = "從 stdin 讀取空格分隔的要檢查的 URL 列表。")]
    # [switch]$Stdin,

    [Parameter(HelpMessage = "為給定的記錄器偵錯輸出。選項：'cmdline'，'checking'，'cache'，'thread'，'plugin'，'all'")]
    [Alias('D')]
    [ValidateSet('cmdline', 'checking', 'cache', 'thread', 'plugin', 'all')]
    [string]$DebugLogger,

    [Parameter(HelpMessage = "輸出到文件 linkchecker-out.TYPE，`$XDG_DATA_HOME/linkchecker/failures 用於錯誤時的輸出，或者指定的 FILENAME。")]
    [Alias('F')]
    [string]$FileOutput,

    [Parameter(HelpMessage = "不顯示檢查狀態訊息。")]
    [switch]$NoStatus,

    [Parameter(HelpMessage = "不記錄警告。")]
    [switch]$NoWarnings,

    [Parameter(HelpMessage = "指定輸出格式為 'csv'，'xml'，'dot'，'failures'，'gml'，'gxml'，'html'，'none'，'sitemap'，'sql'，'text'。")]
    [ValidateSet('csv', 'xml', 'dot', 'failures', 'gml', 'gxml', 'html', 'none', 'sitemap', 'sql', 'text')]
    [Alias('o')]
    [string]$Output,

    [Parameter(HelpMessage = "不輸出任何訊息到 Console，不可以跟 -Output 一起使用。")]
    [Alias('q')]
    [switch]$Quiet,

    [Parameter(HelpMessage = "記錄所有 URL，包含 HTTP 200 回應的連結。")]
    [Alias('v')]
    [switch]$LogAll,

    [Parameter(HelpMessage = "讀取包含初始 cookie 資料的文件。")]
    [string]$CookieFile,

    [Parameter(HelpMessage = "忽略 robots.txt 限制。")]
    [switch]$NoRobots,

    [Parameter(HelpMessage = "檢查外部 URL。")]
    [switch]$CheckExtern,

    [Parameter(HelpMessage = "只檢查與給定正則表達式匹配的 URL 的語法。")]
    [string]$IgnoreUrl,

    [Parameter(HelpMessage = "檢查但不遞迴進入與給定正則表達式匹配的 URL。")]
    [string]$NoFollowUrl,

    [Parameter(HelpMessage = "從控制台讀取密碼並用於 HTTP 和 FTP 授權。")]
    [Alias('p')]
    [switch]$Password,

    [Parameter(HelpMessage = "遞迴檢查所有連結，直至給定深度。")]
    [Alias('r')]
    [int]$RecursionLevel = 1,

    [Parameter(HelpMessage = "設定連接嘗試的超時時間（秒）。")]
    [int]$Timeout,

    [Parameter(HelpMessage = "嘗試用於 HTTP 和 FTP 授權的給定使用者名稱。")]
    [Alias('u')]
    [string]$User,

    [Parameter(HelpMessage = "指定要發送到 HTTP 伺服器的 User-Agent 字串。")]
    [string]$UserAgent
)

$arguments = @()

if ($Config) { $arguments += "-f", $Config }
if ($Threads) { $arguments += "-t", $Threads }
if ($Version) { $arguments += "-V" }
if ($ListPlugins) { $arguments += "--list-plugins" }

# if ($Stdin) { $arguments += "--stdin" }

if ($DebugLogger) { $arguments += "-D", $DebugLogger }
if ($FileOutput) { $arguments += "-F", $FileOutput }

if ($NoStatus) { $arguments += "--no-status" }
if ($NoWarnings) { $arguments += "--no-warnings" }

if ($Output) { $arguments += "-o", $Output }
if ($Quiet) { $arguments += "-o none" }

if ($LogAll) { $arguments += "--verbose" }
if ($CookieFile) { $arguments += "--cookiefile", $CookieFile }
if ($NoRobots) { $arguments += "--no-robots" }
if ($CheckExtern) { $arguments += "--check-extern" }
if ($IgnoreUrl) { $arguments += "--ignore-url", $IgnoreUrl }
if ($NoFollowUrl) { $arguments += "--no-follow-url", $NoFollowUrl }
if ($Password) { $arguments += "-p" }
if ($RecursionLevel) { $arguments += "-r", $RecursionLevel }
if ($Timeout) { $arguments += "--timeout", $Timeout }
if ($User) { $arguments += "-u", $User }
if ($UserAgent) { $arguments += "--user-agent", $UserAgent }

if ($Url) { $arguments += $Url }

# You can install linkchecker by using the following command:
# pip3 install linkchecker
& "linkchecker.exe" $arguments

# SIG # Begin signature block
# MIISOQYJKoZIhvcNAQcCoIISKjCCEiYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCfjNCD3geUP6cx
# HdlsbVZtuFjnXdSnujgNQxrL6ZuWtqCCDnEwggboMIIE0KADAgECAhB3vQ4Ft1kL
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
# BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCah+my+YrDgJa4u7mBXuMfitxXXblC
# 1k2CZyZeAUVC/jANBgkqhkiG9w0BAQEFAASCAgBNM0AVXXu+WWTacgwCYDh+O/8f
# eT/mt1uxxiZTDu8yxQYdQIOueTiSGHlw8BGCzkHiPSi6xK6pXC1EmsrO+P7hN9Fb
# PuCU042QBgu+d5pXTtve7wAzXk7Oua6Dxhp3OQZ992jTkSCE0+/UGSfvb0SQeb7a
# K8nms9YhxmzKsv/v44cxZSecIfmO6u/6XgwbGKvKMNoL1ausAY39/7EFm56dqTR/
# K/hxzwOnd9FWNAvI5HXsWhWv3FCicljgx6J/tPvTcu2m+F06kIn4faHCd55if0Xs
# wT2MWZa07inO2qr6TtALI+6pZg6TaP4kxyR1tSZ1JSfBMkxQ5kQP/4yVe6z5UeOP
# nkS/6DyepSLvrls7nEa281cENyzoIdbNYWayVE188z+Vtk8yEvl2swihWpi0axvZ
# YxsXBQmF4O3VEPkV+Mfz6JWOfNSGtmJ4KrM+TtiRQlH3DfGzxdvjs3dfMxhH1Fae
# peeeuop0aEr+UjDcQ0yopEK566sS+TRDYtyxdovYlBfChZnrxPHETWFAABAIky38
# HCl7SP5doIH6Um4WIPLxwUDHI86UNqEEEQtovu9ZxQwojR3LF9W8VoUYL2a18GNj
# j4yA/LN1812E14RSVjniI9GVwu6Gs1pkrBZEkykGSulA57QFzB+a3+5e4q0wZPR/
# 1r7QplVxA9M/5lPZYQ==
# SIG # End signature block
