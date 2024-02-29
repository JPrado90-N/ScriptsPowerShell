function ConvertToFormattedDate($originalDate) {
	# Formats the date on the file
	$transformedDate = [DateTime]::ParseExact($originalDate, "M/d/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
	return $transformedDate.ToString("M/d/yyyy h:mm:ss tt")
}

function AddConservationApplicationResource($installDate, $Application, $AssetType, $Model, $Manufacturer, $Quantity, $AuditType) {
	<#This function will create the application resources#>
	$formattedDate = ConvertToFormattedDate $installDate

	$Asset = [AdvancedUtility.Services.BusinessObjects.Asset]::GetAllWhere($CisSession, "C_ASSETTYPE='$AssetType' AND C_MODEL='$Model' AND C_MANUFACTURER='$Manufacturer'")
	
	$NewResource = [AdvancedUtility.Services.BusinessObjects.ConservationApplicationResource]:: { New }($CisSession)
	$NewResource.InstallDate = $formattedDate
	$NewResource.Quantity = $Quantity
	$NewResource.AssetId = $Asset[0].AssetId
	$NewResource.ApplicationId = $Application[0].ApplicationId
    
	try {
		$SaveResult = $NewResource.Save()
		$inforsave = [AdvancedUtility.Common.Text]::Raw([String]::Format("Added successfully: Asset {0} - AuditType {1} - Account {2}", $NewResource.AssetId, $AuditType, $NewResource.Model))
		$this.Interface.CreateLogEntry($inforsave)
	}
	catch [Exception] {
		$errortext = [AdvancedUtility.Common.Text]::Raw([String]::Format("Error: {0}. Asset {1} - AuditType {2}", $_.Exception.Message, $NewResource.AssetId, $AuditType))
		$this.Interface.CreateLogEntry($errortext)
		$return = $false
	}
	finally {
	}
}
	
function AddConservationApplication($Account, $Customer, $ApplicationDate, $Notes, $ProgramId, $Status) {
	<#This function will create the application#>
	$formattedDate = ConvertToFormattedDate $installDate
	
	$NewApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]:: { New }($CisSession)
	$NewApplication.ApplicationDate = $formattedDate
	$NewApplication.Account = $Account
	$NewApplication.Customer = $Customer
	$NewApplication.PaymentOption = '1'
	$NewApplication.Notes = $Notes
	$NewApplication.ProgramId = $ProgramId
	$NewApplication.Status = $Status
    
	try {
		$SaveResult = $NewApplication.Save()
		$inforsave = [AdvancedUtility.Common.Text]::Raw([String]::Format("Added successfully: ApplicationId {0} - AuditType {1} - Account {2}", $NewApplication.ApplicationId, $AuditType, $NewApplication.Account))
		$this.Interface.CreateLogEntry($inforsave)
	}
	catch [Exception] {
		$errortext = [AdvancedUtility.Common.Text]::Raw([String]::Format("Error: {0}. ApplicationId {1} - ", $_.Exception.Message, $NewApplication.ApplicationId, $AuditType))
		$this.Interface.CreateLogEntry($errortext)
		$return = $false
	}
	finally {
	}
}

$Problem = $this.Input.CMOD.Problem

if ($Problem -eq 'INDR') {
	$dateToUse = $this.Input.CMOD.IndrAuditDate
	$originalDate1 = $dateToUse
	$transformedDate1 = [DateTime]::ParseExact($originalDate1, "M/d/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
	$formattedDate1 = $transformedDate1.ToString("M/d/yyyy")

	$ProgramId = $this.Input.CMOD.IndrAuditType
	$account = $this.Processor.FormatAccountNumber($this.Input.CMOD.IndrAcctno)
	$where = "C_ACCOUNT = '$account' AND c_accountstatus = 'AC' "
	$bif003rec = [AdvancedUtility.Services.BusinessObjects.CustomerAccount]::GetAllWhere($CisSession, $where)
	$customer = $bif003rec[0].Customer
	
	switch ($ProgramId) {
		"WES" {
			$PrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='11' ORDER BY i_APPLICATIONID desc", $account, $customer)
			function AddConservationResources($dateToUse, $Application, $resourceType, $model, $manufacturer, $quantity, $auditType) {
				<#Add conservation resources#>
				$typeToUse = $resourceType
			
				if ($resourceType -eq 'SB') {
					$typeToUse = if ($IndrSB407COMP -eq 'Y') { '0033' } elseif ($IndrSB407COMP -eq 'N') { '0034' } else { $resourceType }
				}
			
				if ($quantity -gt 0) {
					AddConservationApplicationResource $dateToUse $Application $typeToUse $model $manufacturer $quantity $auditType
				}
			}
			
			function ProcessConservationApplication($account, $customer, $dateToUse, $notes, $programId, $status, $auditType) {
				AddConservationApplication $account $customer $dateToUse $notes $programId $status
			
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='{2}' ORDER BY i_APPLICATIONID desc", $account, $customer, $programId)
			
				$resourceData = @{
					SB407COMP       = @('SB', '0033', 'GNRC', '0');
					Aerators        = @('AER', '0001', 'GNRC', $IndrTotalAerators);
					EffShowHeads    = @('SHW', '0015', 'GNRC', $IndrTotalEffShowHeads);
					EffWashers      = @('CLT', '0006', 'GNRC', $IndrTotalEffWashers);
					HET             = @('TLT', '0019', 'GNRC', $IndrTotalHET);
					HighFlow        = @('TLT', '0020', 'GNRC', $IndrTotalHighFlow);
					NonEffAerators  = @('AER', '0002', 'GNRC', $IndrTotalNonEffAerators);
					NonEffShowHeads = @('SHW', '0016', 'GNRC', $IndrTotalNonEffShowerHeads);
					NonEffWashers   = @('CLT', '0007', 'GNRC', $IndrTotalNonEffWashers);
					Toilet          = @('TLT', '0021', 'GNRC', $IndrTotalToilet);
					ULFT            = @('TLT', '0023', 'GNRC', $IndrTotalULFT);
				}
			
				foreach ($resource in $resourceData.GetEnumerator()) {
					AddConservationResources $dateToUse $Application $resource.Key $resource.Value[0..3] $auditType
				}
			}
			# Check if the date is not a future date
			if (($null -eq @($PrevApplication)[0] -or $formattedDate1 -ne @($PrevApplication)[0].ApplicationDate.ToString("M/d/yyyy")) -and $formattedDate1 -le (Get-Date).ToString("M/d/yyyy")) {
				ProcessConservationApplication $account $customer $dateToUse $this.Input.CMOD.IndrNotes '11' 'Completed' $this.Input.CMOD.IndrAuditType
			}
		}
		"GWPRE" {
			$PrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='19' ORDER BY i_APPLICATIONID desc", $account, $customer)
	
			if ($null -eq @($PrevApplication)[0]) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.IndrNotes '19' 'InProgress'
			}
			elseif ($formattedDate1 -ne @($PrevApplication)[0].ApplicationDate.ToString("M/d/yyyy")) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.IndrNotes '19' 'InProgress'
			}
		}
		"GWREB" {
			$IndrGWAvgGal = $this.Input.CMOD.IndrGWAvgGal
			if ($IndrGWAvgGal -gt '0') {
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='19' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$Application[0].RebateAmount = $IndrGWAvgGal
				$Application[0].Status = 'Completed'
				$result = $Application[0].Save()
				#Resources to be Added
		
				AddConservationApplicationResource $dateToUse $Application 'GREY' '0013' 'GNRC' $IndrGWAvgGal $this.Input.CMOD.IndrAuditType
			}
		
		}
		"RECIRC" {
			$INDRRPNUMBER = $this.Input.CMOD.INDRRPNUMBER
			if ($INDRRPNUMBER -eq '0' -or $INDRRPNUMBER -eq '') {
				$RcPrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='26' ORDER BY i_APPLICATIONID desc", $account, $customer)
				if ($null -eq @($RcPrevApplication)[0]) {
					AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.IndrNotes '26' 'InProgress'
				}
				elseif ($formattedDate1 -ne @($RcPrevApplication)[0].ApplicationDate.ToString("M/d/yyyy")) {
					AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.IndrNotes '26' 'InProgress'
				}
			}
			else {
				$RcPrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='26' ORDER BY i_APPLICATIONID desc", $account, $customer)
			
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='26' ORDER BY i_APPLICATIONID desc", $account, $customer) 
				#Resources to be Added
				AddConservationApplicationResource $dateToUse $Application 'HOT' 'GM' 'GNRC' $INDRRPNUMBER $this.Input.CMOD.IndrAuditType
			}	
		}
    
	}
	
}
else {
	$dateToUse = $this.Input.CMOD.OutdAuditDate
	$originalDate1 = $dateToUse
	$transformedDate1 = [DateTime]::ParseExact($originalDate1, "M/d/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
	$formattedDate1 = $transformedDate1.ToString("M/d/yyyy")
	$ProgramId = $this.Input.CMOD.OutdAuditType
	$account = $this.Processor.FormatAccountNumber($this.Input.CMOD.OutdAcctno)
	$where = "C_ACCOUNT = '$account' AND c_accountstatus = 'AC' "
	$bif003rec = [AdvancedUtility.Services.BusinessObjects.CustomerAccount]::GetAllWhere($CisSession, $where)
	$customer = $bif003rec[0].Customer

	switch ($ProgramId) {
		"GRNPRE" {
			#Getting Previous Grass	
			$GrassPrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
			$IrrgPrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='23' ORDER BY i_APPLICATIONID desc", $account, $customer)
			if ($null -eq @($GrassPrevApplication)[0]) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '8' 'InProgress'
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$OutdSQPrior = $this.Input.CMOD.OutdSQPrior
				if ($OutdSQPrior -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'SQFT' '0017' 'GNRC' $OutdSQPrior $this.Input.CMOD.OutdAuditType	
				}	
			}
			elseif ($formattedDate1 -ne $GrassPrevApplication[0].ApplicationDate.ToString("M/d/yyyy")) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '8' 'InProgress'
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$OutdSQPrior = $this.Input.CMOD.OutdSQPrior
				if ($OutdSQPrior -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'SQFT' '0017' 'GNRC' $OutdSQPrior $this.Input.CMOD.OutdAuditType	
				}
			}
			if ($null -eq @($IrrgPrevApplication)[0]) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '23' 'InProgress'
			}
			elseif ($formattedDate1 -ne $IrrgPrevApplication[0].ApplicationDate.ToString("M/d/yyyy")) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '23' 'InProgress'
		
			}
		}
		"GRNREB" {
			#Resources to be Added
			$OutdIrrigUpgrade = $this.Input.CMOD.OutdIrrigUpgrade
			$OutdCashForGrass = $this.Input.CMOD.OutdCashForGrass
		
			if ($OutdIrrigUpgrade -gt '0') {
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='23' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$Application[0].RebateAmount = $OutdIrrigUpgrade
				$Application[0].Status = 'Completed'
				$result = $Application[0].Save()
				$HENOZZLEREB = $this.Input.CMOD.HENOZZLEREB
				$OutdPressureReg = $this.Input.CMOD.OutdPressureReggrade
				$OutdRainsensor = $this.Input.CMOD.OutdRainsensor
				$OutdSmartRebate = $this.Input.CMOD.OutdSmartRebate
				$OutdDripRetrofitRebate = $this.Input.CMOD.OutdDripRetrofitRebate
			
				if ($HENOZZLEREB -eq 'Y') {
					$valueAmount = '1'
					#AddConservationApplicationResource $dateToUse $Application 'NOZZ' 'GM' 'GNRC' $OutdIrrigUpgrade $this.Input.CMOD.OutdAuditType
					AddConservationApplicationResource $dateToUse $Application 'NOZZ' 'GM' 'GNRC' $valueAmount $this.Input.CMOD.OutdAuditType
				}
				if ($OutdPressureReg -eq 'Y') {
					#AddConservationApplicationResource $dateToUse $Application 'PRRD' 'GM' 'GNRC' $OutdIrrigUpgrade $this.Input.CMOD.OutdAuditType
					$valueAmount = '1'
					AddConservationApplicationResource $dateToUse $Application 'PRRD' 'GM' 'GNRC' $valueAmount $this.Input.CMOD.OutdAuditType
				}
				if ($OutdRainsensor -eq 'Y') {
					#AddConservationApplicationResource $dateToUse $Application 'RASN' '0036' 'GNRC' $OutdIrrigUpgrade $this.Input.CMOD.OutdAuditType
					$valueAmount = '1'
					AddConservationApplicationResource $dateToUse $Application 'RASN' 'GM' 'GNRC' $valueAmount $this.Input.CMOD.OutdAuditType
				}
				if ($OutdSmartRebate -eq 'Y') {
					#AddConservationApplicationResource $dateToUse $Application 'SIRT' 'GM' 'GNRC' $OutdIrrigUpgrade $this.Input.CMOD.OutdAuditType
					$valueAmount = '1'
					AddConservationApplicationResource $dateToUse $Application 'SIRT' 'GM' 'GNRC' $valueAmount $this.Input.CMOD.OutdAuditType
				}
				if ($OutdDripRetrofitRebate -eq 'Y') {
					#AddConservationApplicationResource $dateToUse $Application 'DRET' 'GM' 'GNRC' $OutdIrrigUpgrade $this.Input.CMOD.OutdAuditType
					$valueAmount = '1'
					AddConservationApplicationResource $dateToUse $Application 'DRET' 'GM' 'GNRC' $valueAmount $this.Input.CMOD.OutdAuditType
				}
			}
			if ($OutdCashForGrass -gt '0') {
				$Application1 = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$Application1[0].RebateAmount = $OutdCashForGrass
				$Application1[0].Status = 'Completed'
				$result = $Application1[0].Save()
				$OutSQRemoved = $this.Input.CMOD.OutSQRemoved
				AddConservationApplicationResource $dateToUse $Application1 'SQFT' '0018' 'GNRC' $OutSQRemoved $this.Input.CMOD.OutdAuditType
			
			}
			
		}
		"RWPRE" {
			$PrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer)
			if ($null -eq @($PrevApplication)[0]) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '25' 'InProgress'
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$OutdMaxRRGal = $this.Input.CMOD.OutdMaxRRGal
				AddConservationApplicationResource $dateToUse $Application 'RAIN' '0032' 'GNRC' $OutdMaxRRGal $this.Input.CMOD.OutdAuditType
		
			}
			elseif ($formattedDate1 -ne @($PrevApplication)[0].ApplicationDate.ToString("M/d/yyyy")) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '25' 'InProgress'
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$OutdMaxRRGal = $this.Input.CMOD.OutdMaxRRGal
				AddConservationApplicationResource $dateToUse $Application 'RAIN' '0032' 'GNRC' $OutdMaxRRGal $this.Input.CMOD.OutdAuditType
			}
		
		}
		"RWREB" {
			$OutdRainwaterRebate = [double]$this.Input.CMOD.OutdRainwaterRebate
			$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer) 
			$NewNotes = $Application[0].Notes + $this.Input.CMOD.OutdNotes
			$Application[0].Notes = $NewNotes
			$Application[0].Status = 'Completed'
			$result = $Application[0].Save()
			$OutdMaxRRGal = $this.Input.CMOD.OutdMaxRRGal
			$OutdGallonsInstalled = $this.Input.CMOD.OutdGallonsInstalled
			AddConservationApplicationResource $dateToUse $Application 'RAIN' '0014' 'GNRC' $OutdGallonsInstalled $this.Input.CMOD.OutdAuditType
			AddConservationApplicationResource $dateToUse $Application 'RAIN' '0032' 'GNRC' $OutdMaxRRGal $this.Input.CMOD.OutdAuditType
		}
		"WES" {
			$PrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='14' ORDER BY i_APPLICATIONID desc", $account, $customer)
			if ($null -eq @($PrevApplication)[0]) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '14' 'Completed'
			}
			elseif ($formattedDate1 -ne @($PrevApplication)[0].ApplicationDate.ToString("M/d/yyyy")) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '14' 'InProgress'
			}
		}
	}
}

Return $True