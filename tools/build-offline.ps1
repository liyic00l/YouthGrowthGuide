$root = "d:\GitHub\YouthGrowthGuide"
$bookDir = "$root\book"
$files = Get-ChildItem -Path "$bookDir\*.md" | Sort-Object Name
$template = [System.IO.File]::ReadAllText("$root\index.html", [System.Text.Encoding]::UTF8)

$allItems = [System.Collections.Generic.List[Object]]::new()
$regex = [regex]'(?ms)^### (\d+)\.\s*(`\[[^\]]+\]`)\s*(`\[[^\]]+\]`)\s*(.*?)\r?\n(.*?)(?=(?:^### \d+\.)|\Z)'

foreach ($f in $files) {
    $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $matches = $regex.Matches($text)
    foreach ($m in $matches) {
        $num = $m.Groups[1].Value
        $tag1 = $m.Groups[2].Value.Replace('`', '').Replace('[', '').Replace(']', '')
        $tag2 = $m.Groups[3].Value.Replace('`', '').Replace('[', '').Replace(']', '')
        $title = $m.Groups[4].Value.Trim()
        $body = $m.Groups[5].Value

        $cost = ""; $plain = ""; $benefit = ""; $level = ""; $source = ""; $remark = ""; $parentQuote = ""
        
        $mCost = [regex]::Match($body, '- \*\*成本\*\*：([^\r\n]+)')
        if ($mCost.Success) { $cost = $mCost.Groups[1].Value.Trim() }

        $mPlain = [regex]::Match($body, '- \*\*说人话\*\*：([^\r\n]+)')
        if ($mPlain.Success) { $plain = $mPlain.Groups[1].Value.Trim() }

        $mBenefit = [regex]::Match($body, '(?ms)- \*\*收益\*\*：(.*?)(?=(?:- \*\*)|$)')
        if ($mBenefit.Success) { $benefit = $mBenefit.Groups[1].Value.Trim() }

        $mLevel = [regex]::Match($body, '- \*\*证据等级\*\*：([^\r\n]+)')
        if ($mLevel.Success) { $level = $mLevel.Groups[1].Value.Trim() }

        $mSource = [regex]::Match($body, '(?ms)- \*\*来源\*\*：(.*?)(?=(?:- \*\*)|$)')
        if ($mSource.Success) { $source = $mSource.Groups[1].Value.Trim() }

        $mRemark = [regex]::Match($body, '(?ms)- \*\*备注\*\*：(.*?)(?=(?:- \*\*)|$)')
        if ($mRemark.Success) { $remark = $mRemark.Groups[1].Value.Trim() }

        $mQuote = [regex]::Match($remark, '【直接转给爸妈看】：(.*?)$')
        if ($mQuote.Success) { $parentQuote = $mQuote.Groups[1].Value.Trim() }

        $allItems.Add([PSCustomObject]@{
            num = $num; tag1 = $tag1; tag2 = $tag2; title = $title;
            cost = $cost; plain = $plain; benefit = $benefit;
            level = $level; source = $source; remark = $remark;
            parentQuote = $parentQuote; fileName = $f.Name
        })
    }
}

$json = ConvertTo-Json -InputObject $allItems -Depth 4 -Compress
$jsonEscaped = $json.Replace('</script>', '<\/script>')

$offlineHtml = $template.Replace('window.CORPUS_DATA = [];', "window.CORPUS_DATA = $jsonEscaped;")
$offlineHtml = $offlineHtml.Replace('async function init() {', 'async function init() { renderItems(window.CORPUS_DATA); return;')

$outPath = "$root\dist\YouthGrowthGuide_单文件离线版.html"
[System.IO.File]::WriteAllText($outPath, $offlineHtml, [System.Text.Encoding]::UTF8)
$kb = [math]::Round((Get-Item $outPath).Length / 1024)
Write-Output "SUCCESS: Generated $outPath ($kb KB, $($allItems.Count) items)"