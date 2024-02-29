$results = 0
$days = $this.BillRate.Days
if ($this.BillReading -ne $null -and $this.BillReading.UseBilledOverrideConsumption -eq $true) {
    $results = [AdvancedUtility.Common.Utility]::CisRound($this.BillReading.OverrideConsumption, 0)
}
else {
    $periods = [math]::Floor($days / 30)
    if ($this.BillReading -ne $null -and $this.BillReading.BillCode -in @("SPL", "PSL")) {
        # Get the basic multiplier of the Splash Pad Estimate
        $service = $this.Bill.GetService("30")
        $multi5 = $CisSession.Tools.GetServiceBasicMultiplier(5, $service.ServiceGroupId, "30", $this.BillRate.ToDate.AddDays(-1))
        if ($days -gt 32 -and $multi5 -ne 0) {
            #Round the consumption for every period
            $consumption = $periods * [AdvancedUtility.Common.Utility]::CisRound($multi5 * 30, 0)
            $consumption += $multi5 * ($days - ($periods * 30))
        }
        else {
            if ($days -ne 0)
            { $consumption = $multi5 * $days }
            else
            { $consumption = $multi5 }
        }
        $results = [AdvancedUtility.Common.Utility]::CisRound($consumption, 0)
    }
    else {
        $useMultiplier = $false
        if ($this.BillReading -ne $null -and $this.BillReading.BillCode -in @('CR1')) {
            $multi4 = 0
            if ($this.BillService.ServiceGroup -eq "30") { 
                $multi4 = Get-BasicMultiplier 4 $this.BillRate.ToDate.AddDays(-1) 
            }
            else {
                $service = $this.Bill.GetService("30")
                $multi4 = $CisSession.Tools.GetServiceBasicMultiplier(4, $service.ServiceGroupId, "30", $this.BillRate.ToDate.AddDays(-1))
            }
            if ($multi4 -eq 0) {
                $results = Invoke-CisFormula 19
                $useMultiplier = $true
                if ($this.BillReading -ne $null -and $this.BillReading.Service -eq $this.BillService.Service) {
                    if ($this.BillReading.ReadStatus -ne 'MC')
                    { $this.BillReading.ReadStatus = 'AD' }
                }
            }
        }
        if ($useMultiplier -eq $false) {
            $service = $this.Bill.GetService("30")
            $consumption = $this.consumption
            if ($this.BillReading -ne $null -and $service.Days -gt $this.BillService.Days) {
                $meterDays = $this.BillReading.ReadingDate.Subtract( $this.BillReading.ReadFromDt).Days
                if ($meterDays -gt $days) { 
                    $consumption = $consumption * ($days / $meterDays ) 
                }
            }
            $results = [AdvancedUtility.Common.Utility]::CisRound($consumption , 0)
        }
    }
}
$results = [AdvancedUtility.Common.Utility]::CisRound($results, 0)
return $results
