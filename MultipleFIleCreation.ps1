# Define the waste routes
$wasteRoutes = @{
    "Green Waste" = @("G1", "G2", "G3", "G4", "G5", "G6")
    "Recycling"   = @("R1", "R2", "R3", "R4", "R5", "R6", "R7")
    "Trash"       = @("T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10")
}

# Specify the folder path
$folderPath = "\\Ont-cisprdapp\cisprod\CIS4\Import\RW"

# Create empty files for each waste route
foreach ($routeType in $wasteRoutes.Keys) {
    $routes = $wasteRoutes[$routeType]
    foreach ($route in $routes) {
        $filePath = Join-Path -Path $folderPath -ChildPath "$route.xml"
        New-Item -ItemType File -Path $filePath -Force | Out-Null
        Write-Host "Empty file created for $routeType route $route"
    }
}

# Define the days associated with specific routes
$routeDays = @{
    "G6"  = @("Monday", "Tuesday", "Thursday")
    "R7"  = @("Tuesday", "Friday")
    "T10" = @("Tuesday", "Wednesday")
}

# Print days associated with specific routes
foreach ($route in $routeDays.Keys) {
    $days = $routeDays[$route]
    Write-Host "$route routes run on $($days -join ', ')"
}