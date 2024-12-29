# 定義提示字串
$promptMessage = "請依據以下內容用正體中文進行總結並解釋相關概念："

# 讀取命令列參數的內容
$arguments = $args -join " "
$argumentsText = $arguments.Trim()

# 檢查命令列參數是否有內容
if (![string]::IsNullOrWhiteSpace($argumentsText)) {
    # 組合最終的提示字串
    $finalMessage = "$promptMessage`n$argumentsText"
} else {
    # 如果命令列參數為空，則從標準輸入讀取內容
    $inputText = $input | Out-String

    # 幫我過濾 $input 的內容，讓他壓縮給 LLM 分析
    # 刪除所有不含 \r\n 的連續空白，移除連續的斷行只剩下一個
    # $inputText = $inputText -replace '(\r\n\s*){2,}', "`r`n"

    if (![string]::IsNullOrWhiteSpace($inputText)) {
        $finalMessage = "$promptMessage`n$inputText"
    } else {
        # 如果標準輸入也為空，則顯示沒有要提問的內容的訊息
        Write-Host "沒有提問的內容。"
        exit
    }
}

# echo $finalMessage


# Base 編碼提示字串
$base64Message = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($finalMessage))
# URL Encode 提示字串
$encodedMessage = [System.Web.HttpUtility]::UrlEncode($base64Message)

$url = 'https://chatgpt.com/?model=gpt-4o-mini&hints=search#autoSubmit=1&prompt=' + $encodedMessage

# 生成 HTML 內容
$htmlContent = @"
<html>
<head>
<meta http-equiv='refresh' content='0; url=$url'>
</head>
<body>
</body>
</html>
"@

# 設定臨時目錄和 HTML 檔案路徑
$tempDir = [System.IO.Path]::GetTempPath()
$htmlFilePath = [System.IO.Path]::Combine($tempDir, "redirect.html")

# 刪除舊的 HTML 檔案（如果存在）
if (Test-Path $htmlFilePath) {
    Remove-Item $htmlFilePath
}

# 將 HTML 內容寫入檔案
Set-Content -Path $htmlFilePath -Value $htmlContent

# 使用 Chrome 開啟生成的 HTML 檔案
Start-Process "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList "--profile-directory=Default", $htmlFilePath
