<# 
.SYNOPSIS
  FolderLens：統計資料夾（可選擇是否包含子資料夾）檔案數量，輸出前 N 名。

.DESCRIPTION
  會從指定根路徑開始遞迴搜尋檔案，支援：
  - 遞迴彙總（Aggregate）：每個資料夾的檔案數包含其所有子資料夾。
  - 直接統計（Direct）：只計算該資料夾內「當層」檔案數。
  - 依完整路徑或資料夾名稱排除。
  - 物件化輸出：Path、FileCount，方便後續管線加工。

.PARAMETER Path
  起始根路徑（必填）。

.PARAMETER TopN
  輸出前幾名（必填，>=1）。

.PARAMETER Mode
  計數模式：Aggregate（包含整個子樹）或 Direct（僅當層）。預設 Aggregate。

.PARAMETER ExcludePath
  以完整路徑為單位排除（大小寫不敏感）。例如 C:\Windows、D:\Temp\Build。

.PARAMETER ExcludeName
  以資料夾名稱為單位排除（大小寫不敏感），例如 node_modules、.git。

.PARAMETER IncludeHidden
  包含隱藏/系統檔案。預設不包含。

.EXAMPLE
  .\FolderLens.ps1 -Path C:\Repos -TopN 10
  # 以 Aggregate 模式計算子樹總數，輸出前 10 名

.EXAMPLE
  .\FolderLens.ps1 -Path C:\Repos -TopN 5 -Mode Direct -ExcludeName node_modules,.git
  # 只算當層檔案數，且排除資料夾名為 node_modules/.git 的路徑

.EXAMPLE
  .\FolderLens.ps1 -Path D:\Data -TopN 20 | Export-Csv .\top20.csv -NoTypeInformation
  # 輸出為 CSV

.NOTES
  - 預設會跳過 ReparsePoint（避免符號連結/聯結點造成循環）。
  - Access Denied 之類錯誤會被忽略。
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType 'Container' })]
    [string]$Path,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$TopN,

    [Parameter(Mandatory = $false, Position = 2)]
    [ValidateSet('Aggregate','Direct')]
    [string]$Mode = 'Direct',

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludePath,

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeName,

    [switch]$IncludeHidden
)

begin {
    # 正規化根路徑（完整路徑、去尾端斜線）
    $root = (Resolve-Path -LiteralPath $Path).Path.TrimEnd('\')

    # 預設排除清單（維持原行為：僅 C:\Windows）
    $defaultExcludePaths = @("C:\Windows")

    # 組合完整的排除路徑（展開環境變數、正規化、補尾斜線方便 prefix 檢查）
    $normalizedExcludePaths = @()
    foreach ($p in @($defaultExcludePaths + ($ExcludePath | ForEach-Object { $_ }) )) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        try {
            $full = (Resolve-Path -LiteralPath $p -ErrorAction Stop).Path.TrimEnd('\') + '\'
            $normalizedExcludePaths += $full
        } catch {
            # 無法解析的排除路徑就忽略（避免中斷）
            Write-Verbose "Skip invalid ExcludePath: $p"
        }
    }

    # 正規化排除名稱（轉小寫、去空白）
    $normalizedExcludeNames = @()
    foreach ($n in ($ExcludeName | ForEach-Object { $_ })) {
        if (-not [string]::IsNullOrWhiteSpace($n)) {
            $normalizedExcludeNames += $n.Trim().ToLowerInvariant()
        }
    }

    # 判斷某路徑是否被排除（路徑 prefix 或包含指定資料夾名）
    function Test-IsExcluded([string]$dirPath) {
        if ([string]::IsNullOrWhiteSpace($dirPath)) { return $false }
        $p = $dirPath.TrimEnd('\') + '\'

        # 完整路徑前綴比對（不分大小寫）
        foreach ($ex in $normalizedExcludePaths) {
            if ($p.StartsWith($ex, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
        }

        # 目錄名稱比對（任一段等於排除名）
        if ($normalizedExcludeNames.Count -gt 0) {
            $segments = $p.Split('\') | Where-Object { $_ -ne '' }
            foreach ($seg in $segments) {
                if ($normalizedExcludeNames -contains $seg.ToLowerInvariant()) { return $true }
            }
        }
        return $false
    }

    # 建立計數表（Hashtable 效能較佳）
    $counts = [System.Collections.Hashtable]::Synchronized(@{})
}

process {
    try {
        Write-Verbose "FolderLens scanning root: '$root'  Mode: $Mode  TopN: $TopN"
        if ($normalizedExcludePaths.Count -gt 0 -or $normalizedExcludeNames.Count -gt 0) {
            Write-Verbose ("Exclusions: paths[{0}] names[{1}]" -f $normalizedExcludePaths.Count, $normalizedExcludeNames.Count)
        }

        # 檔案列舉選項
        $gciParams = @{
            Path        = $root
            File        = $true
            Recurse     = $true
            ErrorAction = 'SilentlyContinue'
        }
        if ($IncludeHidden) {
            $gciParams['Force'] = $true
        } else {
            # 預設跳過隱藏/系統，也跳過 ReparsePoint 以避免循環
            $gciParams['Attributes'] = '!Hidden','!System','!ReparsePoint'
        }

        $files = Get-ChildItem @gciParams

        foreach ($f in $files) {
            $dir = $f.DirectoryName
            if ([string]::IsNullOrWhiteSpace($dir)) { continue }
            if (Test-IsExcluded -dirPath $dir) { continue }

            switch ($Mode) {
                'Direct' {
                    # 只計算直接父目錄
                    $key = $dir
                    $counts[$key] = 1 + ($counts[$key] | ForEach-Object { $_ }) 
                }
                'Aggregate' {
                    # 遞迴把檔案數加到每一層祖先目錄，直到 root 為止
                    $cur = $dir.TrimEnd('\')
                    while ($true) {
                        if (Test-IsExcluded -dirPath $cur) { break }
                        $counts[$cur] = 1 + ($counts[$cur] | ForEach-Object { $_ })
                        if ($cur.Equals($root, [System.StringComparison]::OrdinalIgnoreCase)) { break }
                        $parent = Split-Path -Path $cur -Parent
                        if ([string]::IsNullOrWhiteSpace($parent)) { break }
                        $cur = $parent.TrimEnd('\')
                        # 若已走出 root 範圍就停
                        if (-not ($cur.TrimEnd('\') + '\').StartsWith($root.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) { break }
                    }
                }
            }
        }

        # 產出物件並排序、取前 N 名
        $result =
            $counts.GetEnumerator() |
            ForEach-Object { [PSCustomObject]@{ Path = $_.Key; FileCount = [int]$_.Value } } |
            Sort-Object -Property FileCount -Descending |
            Select-Object -First $TopN

        # 物件化輸出（讓呼叫端自由處理）
        $result
    }
    catch {
        Write-Error "FolderLens 遇到未預期錯誤：$($_.Exception.Message)"
    }
}
