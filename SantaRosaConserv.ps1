function ConvertToFormattedDate($originalDate) {
	<#Formats the date on the file#>
	$transformedDate = [DateTime]::ParseExact($originalDate, "M/d/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
	return $transformedDate.ToString("M/d/yyyy h:mm:ss tt")
}

function AddConservationApplicationResource($installDate, $Application, $AssetType, $Model, $Manufacturer, $Quantity, $AuditType) {
	<#This function will create the application resources#>
	try {
		$formattedDate = ConvertToFormattedDate $installDate
	
		$Asset = [AdvancedUtility.Services.BusinessObjects.Asset]::GetAllWhere($CisSession, "C_ASSETTYPE='$AssetType' AND C_MODEL='$Model' AND C_MANUFACTURER='$Manufacturer'")
    
		$NewResource = [AdvancedUtility.Services.BusinessObjects.ConservationApplicationResource]:: { New }($CisSession)
    
		$NewResource.InstallDate = $formattedDate
		$NewResource.Quantity = [int]$Quantity
		$NewResource.AssetId = $Asset[0].AssetId
		$NewResource.ApplicationId = $Application[0].ApplicationId
		if ($Asset[0].AssetId -eq $null) {
			throw 'Asset is not added to the Inventory.'
		}
    
		$SaveResult = $NewResource.Save()
		$inforsave = [AdvancedUtility.Common.Text]::Raw([String]::Format("Application Ressource Added successfully: Asset {0} - AuditType {1} - Account {2}", $NewResource.AssetId, $AuditType, $NewResource.Model))
		$this.Interface.CreateLogEntry($inforsave)
	}
 catch [Exception] {
		$Validation = $NewResource.Validate()
		$errortext = [AdvancedUtility.Common.Text]::Raw([String]::Format("Error when Adding Application Resource: {0}. Asset {1} - AuditType {2} - Validation Error {3}", $_.Exception.Message, $NewResource.AssetId, $AuditType, $Validation[0]))
		$this.Interface.CreateLogEntry($errortext)
	}
 finally {
	}
}

function AddConservationApplication($Account, $Customer, $ApplicationDate, $Notes, $ProgramId, $Status) {
	<#This function will create the application#>
	try {
		$formattedDate = ConvertToFormattedDate $ApplicationDate

		$NewApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]:: { New }($CisSession)
    
		$NewApplication.ApplicationDate = $formattedDate
		$NewApplication.Account = $Account
		$NewApplication.Customer = $Customer
		$NewApplication.PaymentOption = '1'
		$NewApplication.Notes = $Notes
		$NewApplication.ProgramId = $ProgramId
		$NewApplication.Status = $Status
    
    
		$SaveResult = $NewApplication.Save()
		$inforsave = [AdvancedUtility.Common.Text]::Raw([String]::Format("Application Added successfully: ApplicationId {0} - AuditType {1} - Account {2}", $NewApplication.ApplicationId, $AuditType, $NewApplication.Account))
		$this.Interface.CreateLogEntry($inforsave)
	}
 catch [Exception] {
		$errortext = [AdvancedUtility.Common.Text]::Raw([String]::Format("Error when Adding Application: {0}. ApplicationId {1} - ", $_.Exception, $NewApplication.ApplicationId, $AuditType))
		$
		$this.Interface.CreateLogEntry($errortext)
		$return = $false
	}
 finally {
	}
}

$Problem = $this.Input.CMOD.Problem
$return = $True

if ($Problem -eq 'INDR') {
	$dateToUse = $this.Input.CMOD.IndrAuditDate
	$originalDate1 = $dateToUse
	$transformedDate1 = [DateTime]::ParseExact($originalDate1, "M/d/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
	$formattedDate1 = $transformedDate1.ToString("M/d/yyyy")
	$condition2 = $formattedDate1 -le (Get-Date).ToString("M/d/yyyy")	

	$ProgramId = $this.Input.CMOD.IndrAuditType
	$account = $this.Processor.FormatAccountNumber($this.Input.CMOD.IndrAcctno)
	$where = "C_ACCOUNT = '$account' AND c_accountstatus = 'AC' "
	$bif003rec = [AdvancedUtility.Services.BusinessObjects.CustomerAccount]::GetAllWhere($CisSession, $where)
	$customer = $bif003rec[0].Customer
	
	switch ($ProgramId) {
		"WES" {
			$PrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='11' ORDER BY i_APPLICATIONID desc", $account, $customer)
			$condition1 = ($null -eq @($PrevApplication)[0] -or $formattedDate1 -ne @($PrevApplication)[0].ApplicationDate.ToString("M/d/yyyy"))
		
			if ($condition1 -and $condition2) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.IndrNotes '11' 'Completed'

				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='11' ORDER BY i_APPLICATIONID desc", $account, $customer) 
				#Resources to be Added
				$IndrSB407COMP = $this.Input.CMOD.IndrSB407COMP
				$IndrTotalAerators = $this.Input.CMOD.IndrTotalAerators
				$IndrTotalEffShowHeads = $this.Input.CMOD.IndrTotalEffShowHeads
				$IndrTotalEffWashers = $this.Input.CMOD.IndrTotalEffWashers
				$IndrTotalHET = $this.Input.CMOD.IndrTotalHET
				$IndrTotalHighFlow = $this.Input.CMOD.IndrTotalHighFlow
				$IndrTotalNonEffAerators = $this.Input.CMOD.IndrTotalNonEffAerators
				$IndrTotalNonEffShowerHeads = $this.Input.CMOD.IndrTotalNonEffShowerHeads
				$IndrTotalNonEffWashers = $this.Input.CMOD.IndrTotalNonEffWashers
				$IndrTotalToilet = $this.Input.CMOD.IndrTotalToilet
				$IndrTotalULFT = $this.Input.CMOD.IndrTotalULFT
	
				if ($IndrSB407COMP -eq 'Y') {
					AddConservationApplicationResource $dateToUse $Application 'SB' '0033' 'GNRC' '0' $this.Input.CMOD.IndrAuditType
			
				}
				elseif ($IndrSB407COMP -eq 'N') {
					AddConservationApplicationResource $dateToUse $Application 'SB' '0034' 'GNRC' '0' $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalAerators -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'AER' '0001' 'GNRC' $IndrTotalAerators $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalEffShowHeads -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'SHW' '0015' 'GNRC' $IndrTotalEffShowHeads $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalEffWashers -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'CLT' '0006' 'GNRC' $IndrTotalEffWashers $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalHET -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'TLT' '0019' 'GNRC' $IndrTotalHET $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalHighFlow -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'TLT' '0020' 'GNRC' $IndrTotalHighFlow $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalNonEffAerators -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'AER' '0002' 'GNRC' $IndrTotalNonEffAerators $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalNonEffShowerHeads -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'SHW' '0016' 'GNRC' $IndrTotalNonEffShowerHeads $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalNonEffWashers -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'CLT' '0007' 'GNRC' $IndrTotalNonEffWashers $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalToilet -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'TLT' '0021' 'GNRC' $IndrTotalToilet $this.Input.CMOD.IndrAuditType
				}
				if ($IndrTotalULFT -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'TLT' '0023' 'GNRC' $IndrTotalULFT $this.Input.CMOD.IndrAuditType
				}
			}
		
		
		}
		"GWPRE" {
			$PrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='19' ORDER BY i_APPLICATIONID desc", $account, $customer)
			$condition1 = ($null -eq @($PrevApplication)[0] -or $formattedDate1 -ne @($PrevApplication)[0].ApplicationDate.ToString("M/d/yyyy"))

			if ($condition1 -and $condition2) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.IndrNotes '19' 'InProgress'
			}
		}
		"GWREB" {
			$IndrGWAvgGal = $this.Input.CMOD.IndrGWAvgGal
			$IndrGWRebate = $this.Input.CMOD.IndrGWRebate
			if ($IndrGWAvgGal -gt '0') {
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='19' ORDER BY i_APPLICATIONID desc", $account, $customer)
				<#Adding the resource to the application#>
				AddConservationApplicationResource $dateToUse $Application 'GREY' '0013' 'GNRC' $IndrGWAvgGal $this.Input.CMOD.IndrAuditType
			}
		}
		"RECIRC" {
			$INDRRPNUMBER = $this.Input.CMOD.INDRRPNUMBER
			$RcPrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='26' ORDER BY i_APPLICATIONID desc", $account, $customer)
			if ($INDRRPNUMBER -eq '0' -or $INDRRPNUMBER -eq '') {
				$RcPrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='26' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$condition1 = ($null -eq @($RcPrevApplication)[0] -or $formattedDate1 -ne @($RcPrevApplication)[0].ApplicationDate.ToString("M/d/yyyy"))
			
				if ($condition1 -and $condition2) {
					AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.IndrNotes '26' 'InProgress'
				}
			}
			else {
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
	$condition3 = $formattedDate1 -le (Get-Date).ToString("M/d/yyyy")
	
	$ProgramId = $this.Input.CMOD.OutdAuditType
	$account = $this.Processor.FormatAccountNumber($this.Input.CMOD.OutdAcctno)
	$where = "C_ACCOUNT = '$account' AND c_accountstatus = 'AC' "
	$bif003rec = [AdvancedUtility.Services.BusinessObjects.CustomerAccount]::GetAllWhere($CisSession, $where)
	$customer = $bif003rec[0].Customer

	switch ($ProgramId) {
		"GRNPRE" {
			<#Obtaining Previous Irrigation And Grass Applications#>
			$GrassPrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
			$IrrgPrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='23' ORDER BY i_APPLICATIONID desc", $account, $customer)
		
			$condition1 = ($null -eq @($GrassPrevApplication)[0] -or $formattedDate1 -ne @($GrassPrevApplication)[0].ApplicationDate.ToString("M/d/yyyy"))
			$condition2 = ($null -eq @($IrrgPrevApplication)[0] -or $formattedDate1 -ne @($IrrgPrevApplication)[0].ApplicationDate.ToString("M/d/yyyy"))
			$condition3 = $formattedDate1 -le (Get-Date).ToString("M/d/yyyy")
		
			if ($condition1 -and $condition3) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '8' 'InProgress'
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$Application1 = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='23' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$OutdSQPrior = $this.Input.CMOD.OutdSQPrior
				if ($OutdSQPrior -gt '0') {
					AddConservationApplicationResource $dateToUse $Application 'SQFT' '0017' 'GNRC' $OutdSQPrior $this.Input.CMOD.OutdAuditType	
				}	
			}
			if ($condition2 -and $condition3) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '23' 'InProgress'
		
			}
		}
		"GRNREB" {
			#Resources to be Added
			$OutdIrrigUpgrade = $this.Input.CMOD.OutdIrrigUpgrade
			$OutdCashForGrass = $this.Input.CMOD.OutdCashForGrass
			if ($condition3) {
				if ($OutdIrrigUpgrade -gt '0') {
					$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='23' ORDER BY i_APPLICATIONID desc", $account, $customer)
			
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
					$OutSQRemoved = $this.Input.CMOD.OutSQRemoved
					AddConservationApplicationResource $dateToUse $Application1 'SQFT' '0018' 'GNRC' $OutSQRemoved $this.Input.CMOD.OutdAuditType
			
				}
			}
			
		}
		"RWPRE" {
			$PrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer)
			$condition1 = ($null -eq @($PrevApplication)[0] -or $formattedDate1 -ne @($PrevApplication)[0].ApplicationDate.ToString("M/d/yyyy"))
		
			if ($condition1 -and $condition3) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '25' 'InProgress'
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$OutdMaxRRGal = $this.Input.CMOD.OutdMaxRRGal
				AddConservationApplicationResource $dateToUse $Application 'RAIN' '0032' 'GNRC' $OutdMaxRRGal $this.Input.CMOD.OutdAuditType
			}		
		}
		"RWREB" {
			if ($condition3) {
				$OutdRainwaterRebate = $this.Input.CMOD.OutdRainwaterRebate
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer) 
				$OutdMaxRRGal = $this.Input.CMOD.OutdMaxRRGal
				$OutdGallonsInstalled = $this.Input.CMOD.OutdGallonsInstalled
				AddConservationApplicationResource $dateToUse $Application 'RAIN' '0014' 'GNRC' $OutdGallonsInstalled $this.Input.CMOD.OutdAuditType
				AddConservationApplicationResource $dateToUse $Application 'RAIN' '0032' 'GNRC' $OutdMaxRRGal $this.Input.CMOD.OutdAuditType
			}
		}
		"WES" {
			$PrevApplication = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='14' ORDER BY i_APPLICATIONID desc", $account, $customer)
			$condition1 = ($null -eq @($PrevApplication)[0] -or $formattedDate1 -ne @($PrevApplication)[0].ApplicationDate.ToString("M/d/yyyy"))
			if ($condition1 -and $condition3) {
				AddConservationApplication $account $customer $dateToUse $this.Input.CMOD.OutdNotes '14' 'Completed'
			}
		}
	}
}
<#Rebate Amounts#>
if ($Problem -eq 'INDR') {
	switch ($ProgramId) {
		"GWREB" {
			if ($IndrGWAvgGal -gt '0') {
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='19' ORDER BY i_APPLICATIONID desc", $account, $customer)
				if ($Application[0].Status -ne 'Completed') {
					$Application[0].RebateAmount = $IndrGWRebate
					$NewNotes = $Application[0].Notes + $this.Input.CMOD.IndrNotes
					$Application[0].Notes = $NewNotes
					$Application[0].Status = 'Completed'
					$result = $Application[0].Save()
				}
			}
		}
		"RECIRC" {
			if ($INDRRPNUMBER -ne '0' -or $INDRRPNUMBER -ne '') {
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='26' ORDER BY i_APPLICATIONID desc", $account, $customer) 
				if ($Application[0].Status -ne 'Completed') {
					$NewNotes = $Application[0].Notes + $this.Input.CMOD.IndrNotes
					$Application[0].Notes = $NewNotes
					$Application[0].RebateAmount = $INDRPREREBATE
					$Application[0].Status = 'Completed'
					$result = $Application[0].Save()
				}			
			}	
		}
    
	}	
}
else {
	switch ($ProgramId) {
		"GRNPRE" {
			if ($condition1 -and $condition3) {
				if ($OutdSQPrior -gt '0') {
					$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
					$NewNotes = $Application[0].Notes + $this.Input.CMOD.OutdNotes
					$Application[0].Notes = $NewNotes
					$Application[0].RebateAmount = $OutdCashForGrass
					$result = $Application[0].Save()
				}	
			}
			if ($condition2 -and $condition3) {
				$Application1 = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='23' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$NewNotes = $Application1[0].Notes + $this.Input.CMOD.OutdNotes
				$Application1[0].Notes = $NewNotes
				$Application1[0].RebateAmount = $OutdCashForGrass
				$result = $Application1[0].Save()
			}
		}
		"GRNREB" {
			$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='23' ORDER BY i_APPLICATIONID desc", $account, $customer)	
			$Application1 = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
			if ($Application[0].Status -ne 'Completed') {
				if ($OutdIrrigUpgrade -gt '0') {
					$Application[0].RebateAmount = $OutdIrrigUpgrade
					$Application[0].Status = 'Completed'
					$result = $Application[0].Save()
				}
			}
			if ($Application1[0].Status -ne 'Completed') {
				if ($OutdCashForGrass -gt '0') {
					$Application1[0].RebateAmount = $OutdCashForGrass
					$Application1[0].Status = 'Completed'
					$result = $Application1[0].Save()
				}
			}	
		}
		"RWREB" {
			if ($condition3) {
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer) 
				if ($Application[0].Status -ne 'Completed') {
					$NewNotes = $Application[0].Notes + $this.Input.CMOD.OutdNotes
					$Application[0].Notes = $NewNotes
					$Application[0].Status = 'Completed'
					$Application[0].RebateAmount = $OutdRainwaterRebate
					$result = $Application[0].Save()
				}
			}
		}

	}
}

