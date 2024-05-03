$fileName = $this.Interface.InputFileName
$nFileName = "\\vs-cisinfapptrain\CISInfinity\NewTemetra\test.csv"
$skipped = "\\vs-cisinfapptrain\CISInfinity\NewTemetra\testSkip.csv"
$skipRecords = @()
$readRecords = @()
$csvData = Import-Csv $fileName

foreach ($item in $csvData) {
    if ($item.READMETHOD -eq 'skip') {
        $skipRecords += $item
    }
    else {
        $readRecords += $item
    }
}
$skipRecords | Export-Csv -Path $skipped -NoTypeInformation
$readRecords | Export-Csv -Path $nFileName -NoTypeInformation

$content = Get-Content $nFileName | Select-Object -Skip 1
$content | Set-Content $nFileName
$this.Interface.InputFileName = $nFileName
return $true