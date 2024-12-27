# 程式碼數位簽章筆記

## 從目前使用者的憑證存儲區中取得代碼簽署憑證，並篩選出符合特定指紋的憑證
$cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Thumbprint -like "*28a7f86e813c879989426e401947473d7fdb911e*" } | Select-Object -First 1

## 使用取得的憑證對指定的 PowerShell 腳本進行簽署，並使用時間戳伺服器
Set-AuthenticodeSignature -FilePath "$env:USERPROFILE\Documents\PowerShell\Scripts\Install-WTCanary.ps1" -Certificate $cert -TimestampServer "http://timestamp.globalsign.com/tsa/r6advanced1"

## 取得指定 PowerShell 腳本的 Authenticode 簽署資訊
Get-AuthenticodeSignature -FilePath "$env:USERPROFILE\Documents\PowerShell\Scripts\Install-WTCanary.ps1"

## 解除對指定 PowerShell 腳本的封鎖
Unblock-File -Path "Install-WTCanary.ps1"
