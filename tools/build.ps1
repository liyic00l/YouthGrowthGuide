$root = "D:\GitHub\YouthGrowthGuide"
$bookDir = Join-Path $root "book"
$files = Get-ChildItem -Path (Join-Path $bookDir "*.md") | Sort-Object Name
$items = [System.Collections.Generic.List[Object]]::new()

function Get-Field([string]$b, [string]$k) {
    $tag = "**" + $k + "**"
    $p = $b.IndexOf($tag)
    if ($p -lt 0) { return "" }
    $s = $b.IndexOf([char]0xff1a, $p)
    if ($s -lt 0) { $s = $b.IndexOf(':', $p) }
    if ($s -lt 0) { return "" }
    $s += 1
    $e = $b.IndexOf("- **", $s)
    if ($e -ge 0) { return $b.Substring($s, $e - $s).Trim() }
    else { return $b.Substring($s).Trim() }
}

foreach ($f in $files) {
    $txt = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $lines = $txt -split "`r?`n"
    
    $curNum = ""
    $curTag1 = ""
    $curTag2 = ""
    $curTitle = ""
    $curBodyList = [System.Collections.Generic.List[string]]::new()

    foreach ($line in $lines) {
        if ($line.StartsWith("### ")) {
            if ($curNum -ne "") {
                $bodyStr = [string]::Join("`n", $curBodyList)
                $cost = Get-Field $bodyStr "成本"
                $plain = Get-Field $bodyStr "说人话"
                $benefit = Get-Field $bodyStr "收益"
                $level = Get-Field $bodyStr "证据等级"
                $source = Get-Field $bodyStr "来源"
                $remark = Get-Field $bodyStr "备注"

                $pq = ""
                $qpos = $remark.IndexOf("【直接转给爸妈看】：")
                if ($qpos -ge 0) {
                    $pq = $remark.Substring($qpos + 10).Trim()
                }

                $items.Add([PSCustomObject]@{
                    num = $curNum
                    tag1 = $curTag1
                    tag2 = $curTag2
                    title = $curTitle
                    cost = $cost
                    plain = $plain
                    benefit = $benefit
                    level = $level
                    source = $source
                    remark = $remark
                    parentQuote = $pq
                    fileName = $f.Name
                })
            }
            $curBodyList.Clear()

            $dotIdx = $line.IndexOf(".", 4)
            if ($dotIdx -gt 0) {
                $curNum = $line.Substring(4, $dotIdx - 4).Trim()
                $rest = $line.Substring($dotIdx + 1).Trim()

                $t1Idx1 = $rest.IndexOf("[")
                $t1Idx2 = $rest.IndexOf("]")
                $curTag1 = if ($t1Idx1 -ge 0 -and $t1Idx2 -gt $t1Idx1) { $rest.Substring($t1Idx1 + 1, $t1Idx2 - $t1Idx1 - 1) } else { "通用" }

                $t2Idx1 = $rest.IndexOf("[", $t1Idx2 + 1)
                $t2Idx2 = $rest.IndexOf("]", $t2Idx1 + 1)
                $curTag2 = if ($t2Idx1 -ge 0 -and $t2Idx2 -gt $t2Idx1) { $rest.Substring($t2Idx1 + 1, $t2Idx2 - $t2Idx1 - 1) } else { "自己就能做" }

                $curTitle = $rest.Substring($t2Idx2 + 1).Trim().TrimStart('`').Trim()
            }
        } else {
            if ($curNum -ne "") {
                $curBodyList.Add($line)
            }
        }
    }

    if ($curNum -ne "") {
        $bodyStr = [string]::Join("`n", $curBodyList)
        $cost = Get-Field $bodyStr "成本"
        $plain = Get-Field $bodyStr "说人话"
        $benefit = Get-Field $bodyStr "收益"
        $level = Get-Field $bodyStr "证据等级"
        $source = Get-Field $bodyStr "来源"
        $remark = Get-Field $bodyStr "备注"

        $pq = ""
        $qpos = $remark.IndexOf("【直接转给爸妈看】：")
        if ($qpos -ge 0) {
            $pq = $remark.Substring($qpos + 10).Trim()
        }

        $items.Add([PSCustomObject]@{
            num = $curNum
            tag1 = $curTag1
            tag2 = $curTag2
            title = $curTitle
            cost = $cost
            plain = $plain
            benefit = $benefit
            level = $level
            source = $source
            remark = $remark
            parentQuote = $pq
            fileName = $f.Name
        })
    }
}

Write-Host "Total items parsed: $($items.Count)"

$json = ConvertTo-Json -InputObject $items -Depth 4 -Compress
$jsonEsc = $json.Replace('</script>', '<\/script>')

$tplPath = Join-Path $root "tools\template-index.html"
$tpl = [System.IO.File]::ReadAllText($tplPath, [System.Text.Encoding]::UTF8)
$outHtml = $tpl.Replace("/*__CORPUS_JSON__*/", "window.CORPUS_DATA = $jsonEsc;")

$indexPath = Join-Path $root "index.html"
$distPath = Join-Path $root "dist\YouthGrowthGuide_单文件离线版.html"

[System.IO.File]::WriteAllText($indexPath, $outHtml, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($distPath, $outHtml, [System.Text.Encoding]::UTF8)

$len = (Get-Item $indexPath).Length
Write-Host "SUCCESS: Built index.html and dist offline file! File length: $len bytes"
