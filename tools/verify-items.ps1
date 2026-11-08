$files = Get-ChildItem -Path  D:\GitHub\YouthGrowthGuide\book_new\*.md | Sort-Object Name
$total = 0
$errors = 0
foreach ($f in $files) {
    $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $matches = [regex]::Matches($c, '(?m)^###\s*(\d+)\.')
    Write-Host ($f.Name + ': ' + $matches.Count + ' items')
    $total += $matches.Count
    foreach ($m in $matches) {
        $id = $m.Groups[1].Value
        # Find item text up to next ### or EOF
        $idx = $m.Index
        $nextM = [regex]::Match($c.Substring($idx + 1), '(?m)^###\s*\d+\.')
        $itemText = if ($nextM.Success) { $c.Substring($idx, $nextM.Index + 1) } else { $c.Substring($idx) }
        
        # Check required fields
        $req = @('成本', '说人话', '收益', '证据等级', '来源', '备注')
        foreach ($r in $req) {
            if (-not ($itemText -match ('\*\*' + $r + '\*\*'))) {
                Write-Host ('  [ERROR] Item ' + $id + ' missing **' + $r + '**') -ForegroundColor Red
                $errors++
            }
        }
    }
}
Write-Host ('====================================')
Write-Host ('TOTAL ITEMS FOUND: ' + $total)
Write-Host ('TOTAL ERRORS: ' + $errors)