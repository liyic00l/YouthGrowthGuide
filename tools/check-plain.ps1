$ErrorActionPreference = "Stop"
$bookDir = Join-Path $PSScriptRoot "..\book"
$files = Get-ChildItem -Path "$bookDir\*.md" | Sort-Object Name
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting YouthGrowthGuide Quality Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$totalItems = 0
$plainLengthExceeded = 0
$missingRequiredFields = 0
$requiredFields = @("- **成本**", "- **说人话**", "- **收益**", "- **证据等级**", "- **来源**", "- **备注**")
foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $items = [regex]::Matches($content, "(?ms)(^### \d+\..*?)(?=(?:^### \d+\.)|\Z)")
    Write-Host "`nChecking: $($file.Name) ($($items.Count) items)" -ForegroundColor Yellow
    foreach ($item in $items) {
        $totalItems++
        $text = $item.Value
        if ($text -match "^### (\d+)\. (.*)") { $num = $matches[1]; $title = $matches[2] } else { $num = "?"; $title = "Unknown" }
        foreach ($field in $requiredFields) {
            if (-not ($text -match [regex]::Escape($field))) {
                Write-Host "  [ERROR] Item $num missing: $field ($title)" -ForegroundColor Red
                $missingRequiredFields++
            }
        }
        if ($text -match "- \*\*说人话\*\*：([^\r\n]+)") {
            $plain = $matches[1].Trim()
            if ($plain.Length -gt 130) {
                Write-Host "  [INFO] Item $num plain text length: $($plain.Length)" -ForegroundColor Magenta
                $plainLengthExceeded++
            }
        }
    }
}
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Check completed! Total items: $totalItems" -ForegroundColor Cyan
Write-Host "Missing required fields: $missingRequiredFields" -ForegroundColor $(if ($missingRequiredFields -eq 0) { "Green" } else { "Red" })
Write-Host "Plain text length hints: $plainLengthExceeded" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
if ($missingRequiredFields -gt 0) { exit 1 } else { exit 0 }
