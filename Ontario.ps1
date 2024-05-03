try {
    $logFilePath = "\\Ont-cisprdapp\cisprod\CIS4\RoutewareLogs\RoutewareLog$(Get-Date -Format "yyyyMMddhhmm").txt"
    # Keys
    $serialNumber = $this.Input.Detail.SerialNumber
    $Route = $this.Input.Detail.RouteName

    # MEF407 and BIF014
    $MEF407 = [AdvancedUtility.Services.BusinessObjects.SolidWasteDetails]::GetByWhere($CisSession, "C_ROUTENUMBER={0} and C_SERIALNUMBER={1}", $Route, $serialNumber)
    $BIF014 = [AdvancedUtility.Services.BusinessObjects.AccountEquipment]::GetByWhere($CisSession, "C_SERIALNUMBER={0} AND D_DATEREMOVED is null", $serialNumber)
    
    # Route Day
    $day = $this.Input.Detail.RouteDay

    # Update BIF014
    $BIF014.Notes = if($this.Input.Detail.DriverComment -ne '' -or $this.Input.Detail.DriverComment -ne $null){"$($this.Input.Detail.DriverComment)"}else{"$($BIF014.Notes)"}
    $BIF014.UDF_Char_1 = $this.Input.Detail.Detail.ContainerLatitude
    $BIF014.EquipmentChar2 = $this.Input.Detail.Detail.ContainerLongitude   
    
    # Update MEF407
    switch ($day) {
        1 {
            $MEF407.MondayCallNumber = $this.Input.Detail.SequenceNumber
        }
        2 {
            $MEF407.TuesdayCallNumber = $this.Input.Detail.SequenceNumber
        }
        3 {
            $MEF407.WednesdayCallNumber = $this.Input.Detail.SequenceNumber
        }
        4 {
            $MEF407.ThursdayCallNumber = $this.Input.Detail.SequenceNumber
        }
        5 {
            $MEF407.FridayCallNumber = $this.Input.Detail.SequenceNumber
        }
        6 {
            $MEF407.MondayCallNumber = $this.Input.Detail.SequenceNumber
        }
        7 {
            $MEF407.MondayCallNumber = $this.Input.Detail.SequenceNumber
        }
    }

    # Saving Records
    $SaveBIF014 = $BIF014.Save()
    $SaveMEF407 = $MEF407.Save()
    if ($SaveBIF014 -and $SaveMEF407) {
        $inforsave = [AdvancedUtility.Common.Text]::Raw([String]::Format("Added successfully:  Account {0} - Serial Number {1} - Route {2}", $This.Input.Detail.CustomerNumber, $serialNumber, $Route))
        $this.Interface.CreateLogEntry($inforsave)
    }
    else {
        throw "Error at '$($SerialNumber)' serial number for account '$($This.Input.Detail.CustomerNumber)'."
    }
       
    $inforsave | Out-File -Append -FilePath $logFilePath
    
}
catch {

    if ($_.Exception -ne $null) {
        $errorVar = $_.Exception.Message -replace "`r`n", " "
    }
    else {
        $errorVar = $_
    }
    $inforsave = [AdvancedUtility.Common.Text]::Raw([String]::Format(" Serial Number: {1} - {0} ", $errorVar, $serialNumber))
    $this.Processor.FailRecord($inforsave)
    $inforsave | Out-File -Append -FilePath $logFilePath
}