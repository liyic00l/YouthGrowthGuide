# Quality validation script for YouthGrowthGuide 20 chapters
$bookDir = "D:\GitHub\YouthGrowthGuide\book_new"
$files = Get-ChildItem -Path "$bookDir\*.md" | Sort-Object Name

$totalItems = 0
$errors = 0
$requiredFields = @("- **成本**", "- **说人话**", "- **收益**", "- **证据等级**", "- **来源**", "- **备注**")

Write-Host "========================================"
Write-Host "Starting YouthGrowthGuide Quality Check (UTF-8)"
Write-Host "========================================"

foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $regex = [regex]'(?ms)^### (\d+)\.\s*(`\[[^\]]+\]`)\s*(`\[[^\]]+\]`)\s*(.*?)\r?\n(.*?)(?=(?:^### \d+\.)|\Z)'
    $matches = $regex.Matches($content)
    Write-Host "Checking $($f.Name): $($matches.Count) items"
    
    foreach ($m in $matches) {
        $totalItems++
        $id = $m.Groups[1].Value
        $title = $m.Groups[4].Value.Trim()
        $body = $m.Groups[5].Value

        foreach ($rf in $requiredFields) {
            if (-not $body.Contains($rf)) {
                Write-Host "  [ERROR] Item $id missing $rf : $title" -ForegroundColor Red
                $errors++
            }
        }

        # Check plain length
        $mPlain = [regex]::Match($body, '- \*\*说人话\*\*：([^\r\n]+)')
        if ($mPlain.Success) {
            $plainText = $mPlain.Groups[1].Value.Trim()
            if ($plainText.Length -gt 150) {
                Write-Host "  [WARN] Item $id '说人话' length ($($plainText.Length) chars > 150): $title" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "========================================"
Write-Host "Checked $totalItems items across $($files.Count) chapters."
Write-Host "Total Errors: $errors"
Write-Host "========================================"

if ($errors -gt 0) {
    exit 1
} else {
    Write-Host "ALL CHECKS PASSED PERFECTLY!" -ForegroundColor Green
    exit 0
}
