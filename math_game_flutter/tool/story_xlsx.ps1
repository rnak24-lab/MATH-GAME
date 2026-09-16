# 엑셀 대본 — Excel COM 으로 xlsx 쓰기/읽기 (node tool/story_template.js 가 호출)
#   story_xlsx.ps1 export <sheets.json> <out.xlsx>
#   story_xlsx.ps1 import <in.xlsx> <out.json>
param([string]$Mode, [string]$A, [string]$B)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function ReadJson($p) { return (Get-Content -Raw -Encoding UTF8 $p | ConvertFrom-Json) }

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false
$xl.DisplayAlerts = $false
try {
  if ($Mode -eq 'export') {
    $sheets = ReadJson $A
    $wb = $xl.Workbooks.Add()
    while ($wb.Worksheets.Count -gt 1) { $wb.Worksheets.Item($wb.Worksheets.Count).Delete() }
    $first = $true
    foreach ($sh in $sheets) {
      if ($first) { $ws = $wb.Worksheets.Item(1); $first = $false } else { $ws = $wb.Worksheets.Add([Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count)) }
      $ws.Name = $sh.name
      $rows = @($sh.rows)
      $nr = $rows.Count; $nc = ($sh.cols).Count
      $arr = New-Object 'object[,]' ($nr + 1), $nc
      for ($c = 0; $c -lt $nc; $c++) { $arr[0, $c] = [string]$sh.cols[$c] }
      for ($r = 0; $r -lt $nr; $r++) { for ($c = 0; $c -lt $nc; $c++) { $v = $rows[$r][$c]; if ($null -eq $v) { $v = '' }; $arr[($r + 1), $c] = [string]$v } }
      $rng = $ws.Range('A1').Resize(($nr + 1), $nc)
      $rng.NumberFormat = '@'
      $rng.Value2 = $arr
      $ws.Rows.Item(1).Font.Bold = $true
      $ws.Rows.Item(1).Interior.Color = 0xD7EFEB
      for ($c = 0; $c -lt $nc; $c++) { $ws.Columns.Item($c + 1).ColumnWidth = [double]$sh.widths[$c] }
      $rng.WrapText = $true
      $rng.VerticalAlignment = -4160
      $ws.Activate(); $xl.ActiveWindow.SplitRow = 1; $xl.ActiveWindow.FreezePanes = $true
      if ($sh.editCol -ne $null) { $ws.Columns.Item([int]$sh.editCol + 1).Interior.Color = 0xF0F8FF }
    }
    $wb.Worksheets.Item(1).Activate()
    if (Test-Path $B) { Remove-Item $B -Force }
    $wb.SaveAs($B, 51)
    $wb.Close($false)
    Write-Output "EXPORTED $B"
  }
  elseif ($Mode -eq 'import') {
    $wb = $xl.Workbooks.Open($A, 0, $true)
    $out = @{}
    foreach ($ws in $wb.Worksheets) {
      $ur = $ws.UsedRange
      $vals = $ur.Value2
      $rows = @()
      if ($vals -is [System.Array]) {
        $nr = $vals.GetLength(0); $nc = $vals.GetLength(1)
        for ($r = 1; $r -le $nr; $r++) {
          $row = @()
          for ($c = 1; $c -le $nc; $c++) { $v = $vals[$r, $c]; if ($null -eq $v) { $v = '' }; $row += [string]$v }
          $rows += , $row
        }
      }
      $out[$ws.Name] = $rows
    }
    $wb.Close($false)
    $json = $out | ConvertTo-Json -Depth 5 -Compress
    [System.IO.File]::WriteAllText($B, $json, (New-Object System.Text.UTF8Encoding $false))
    Write-Output "IMPORTED $B"
  }
} finally {
  $xl.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null
}
