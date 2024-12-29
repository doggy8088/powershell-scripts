# Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
param(
        [ValidateSet('gh', 'git', 'shell')]
        [Alias('t')]
        [String]$Target = 'shell',

        [Parameter(Position=0, ValueFromRemainingArguments)]
        [string]$Prompt
)
begin {
        # Create temporary file to store potential command user wants to execute when exiting
        $executeCommandFile = New-TemporaryFile

        # Store original value of GH_DEBUG environment variable
        $envGhDebug = $Env:GH_DEBUG
}
process {
        if ($PSBoundParameters['Debug']) {
                $Env:GH_DEBUG = 'api'
        }

        gh copilot suggest -t $Target -s "$executeCommandFile" "I'm writing a PowerShell script on Windows. $Prompt"
}
end {
        # Execute command contained within temporary file if it is not empty
        if ($executeCommandFile.Length -gt 0) {
                # Extract command to execute from temporary file
                $executeCommand = (Get-Content -Path $executeCommandFile -Raw).Trim()

                # Insert command into PowerShell up/down arrow key history
                [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($executeCommand)

                # Insert command into PowerShell history
                $now = Get-Date
                $executeCommandHistoryItem = [PSCustomObject]@{
                        CommandLine = $executeCommand
                        ExecutionStatus = [Management.Automation.Runspaces.PipelineState]::NotStarted
                        StartExecutionTime = $now
                        EndExecutionTime = $now.AddSeconds(1)
                }
                Add-History -InputObject $executeCommandHistoryItem

                # Execute command
                Write-Host "`n"
                Invoke-Expression $executeCommand
        }
}
clean {
        # Clean up temporary file used to store potential command user wants to execute when exiting
        Remove-Item -Path $executeCommandFile

        # Restore GH_DEBUG environment variable to its original value
        $Env:GH_DEBUG = $envGhDebug
}

# SIG # Begin signature block
# MIISOQYJKoZIhvcNAQcCoIISKjCCEiYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCM0+PQDv2e1H2V
# VJbQGtzJnOsvwUt8xrYiv08T6WQ+taCCDnEwggboMIIE0KADAgECAhB3vQ4Ft1kL
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
# BgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCKKOOBpYiQGfvQPtzCsZ466JAB5kyX
# tTAj4rdGiLcZkTANBgkqhkiG9w0BAQEFAASCAgAFaCxJ9djedOCdn4whG8z7hTNM
# CoY0QFNW/IrR9LGGnUbNUlZRiV8oJJ5D9aAyfFSQHkKUYM4iBnysdwTU13LsRCvm
# rYkMY2Z5BgH9pdFqvu4bsMJ8gAzzyFR0r2T2XpMOWfNzpFtz4Tz6pyG6m7tvC078
# +Sw7qIhHZFk8QaRBBqlJmpmlYa2bk6nV5IuGXh0kL6Lqvxr2oybaxY+rZWr16rEn
# FT+yPhHAGoGeytuuVhYUxsJNx/OBs8El84dYvCtjMYaOwqp2o5CX9BF3hfb/c+sf
# v0jHGyzg2f08cOueeHzsXdOG4vZR5io1Pgqmvbe8uy7W0S/NIUNqnyno+W3V4VWJ
# HqKLmhUvPNPDSKS7+jOMHaAU08uycWl/fKhRxwlJkzjf+01rF7KrCoDIi4sbds1u
# xYc4ZspHyCTXzopxKTsSbRNSUtS84FuPCprRZdi0qM2juNLTMFWaWg2sqPqav7FG
# LfMcv5V18PVZJaAEolXiIE46lqUjiWV+Sz9BmoneKFsGvhSs8H021fiRGIUreFbR
# WymXhBFDi1HzMKQ/vFalyMBUVShIBnKSdCpcQ4fflXr91fd3HmywgVSNu/E7xOAW
# hE7uUKtxDXYQ3EKQyEmbAHZLuYPsYmVHJJ2wnPQisqekQ58fnXr7fk2mB6MAp0R7
# 3mbzpYupEdDN09UiWw==
# SIG # End signature block
