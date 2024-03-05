$filePath = "C:\Users\jp104702\Documents\Tickets\102333_PSL\File - Copy.txt"

# Get content from file
$content = Get-Content -Path $filePath

# Extract from file
$contentFirstPart = $content[0..8]
$contentSecondPart = $content[11..($content.Count - 1)]

# Extract values from the first part
$linesArray = $contentFirstPart | ForEach-Object { ($_ -split ":")[1].Trim() }
$purchase = $linesArray[2]
$warEndDate = $linesArray[4]
$cost = ($linesArray[5] -split " ")[0].Trim() -replace '\$', ''
$type = ($linesArray[7] -split " ")[0].Trim()

# Process the second part
$meters = $contentSecondPart | ForEach-Object {
    $lineParts = ($_ -split ",", 5) | ForEach-Object { $_.Trim() }
    "$($lineParts[0])*$($lineParts[1])*$($lineParts[1])*$($type)*$($purchase)*$($warEndDate)*$($cost)"
}

# Output to a new file
$meters | Out-File -FilePath "C:\Users\jp104702\Documents\Tickets\102333_PSL\File - Copy1.txt"
