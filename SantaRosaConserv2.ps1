
$Problem = $this.Input.CMOD.Problem


if ($Problem -eq 'INDR') {
	$dateToUse = $this.Input.CMOD.IndrAuditDate
	$ProgramId = $this.Input.CMOD.IndrAuditType
	$account = $this.Processor.FormatAccountNumber($this.Input.CMOD.IndrAcctno)
	$where = "C_ACCOUNT = '$account' AND c_accountstatus = 'AC' "
	$bif003rec = [AdvancedUtility.Services.BusinessObjects.CustomerAccount]::GetAllWhere($CisSession, $where)
	$customer = $bif003rec[0].Customer
	$originalDate1 = $dateToUse
	$transformedDate1 = [DateTime]::ParseExact($originalDate1, "M/d/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
	$formattedDate1 = $transformedDate1.ToString("M/d/yyyy h:mm:ss tt")
	
	switch ($ProgramId) {
		"WES" {
			$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='11' ORDER BY i_APPLICATIONID desc", $account, $customer)
			$workFlow = [AdvancedUtility.Services.BusinessObjects.ConservationApplicationWorkflow]::GetAllWhere($CisSession, "I_APPLICATIONID={0} and c_step='SC'", $Application[0].ApplicationId)
			$workFlow[0].CompletedDate = $formattedDate1
			$result = $workFlow[0].Save()

		}
		"GWPRE" {
		
		}
		"GWREB" {
			$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='19' ORDER BY i_APPLICATIONID desc", $account, $customer) 
			$IndrGWRebate = $this.Input.CMOD.IndrGWRebate
			$NewNotes = $Application[0].Notes + $this.Input.CMOD.IndrNotes
			$Application[0].Notes = $NewNotes
			$Application[0].RebateAmount = $IndrGWRebate
			$result = $Application[0].Save()
		}
		"RECIRC" {
			$INDRRPNUMBER = $this.Input.CMOD.INDRRPNUMBER
			$INDRPREREBATE = $this.Input.CMOD.INDRRPREBATE
	
			$INDRRPNUMBER = $this.Input.CMOD.INDRRPNUMBER
			if ($INDRRPNUMBER -eq '0' -or $INDRRPNUMBER -eq '') {
			
			}
			else {
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='26' ORDER BY i_APPLICATIONID desc", $account, $customer) 
				$NewNotes = $Application[0].Notes + $this.Input.CMOD.IndrNotes
				$Application[0].Notes = $NewNotes
				$Application[0].RebateAmount = $INDRPREREBATE
				$Application[0].Status = 'Completed'
				$result = $Application[0].Save() 
			
			}
		
		
		
			
		}
    
	}
	
}
else {
	$dateToUse = $this.Input.CMOD.OutdAuditDate
	$ProgramId = $this.Input.CMOD.OutdAuditType
	$account = $this.Processor.FormatAccountNumber($this.Input.CMOD.OutdAcctno)
	$where = "C_ACCOUNT = '$account' AND c_accountstatus = 'AC' "
	$bif003rec = [AdvancedUtility.Services.BusinessObjects.CustomerAccount]::GetAllWhere($CisSession, $where)
	$customer = $bif003rec[0].Customer

	switch ($ProgramId) {
		"GRNPRE" {
			
		}
		"GRNREB" {
			#Resources to be Added
			$OutdIrrigUpgrade = $this.Input.CMOD.OutdIrrigUpgrade
			$OutdCashForGrass = $this.Input.CMOD.OutdCashForGrass
		
			if ($OutdIrrigUpgrade -gt '0') {
				$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='23' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$NewNotes = $Application[0].Notes + $this.Input.CMOD.OutdNotes
				$Application[0].Notes = $NewNotes
				$Application[0].RebateAmount = $OutdIrrigUpgrade
				$result = $Application[0].Save()
			}
			if ($OutdCashForGrass -gt '0') {
				$Application1 = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='8' ORDER BY i_APPLICATIONID desc", $account, $customer)
				$NewNotes = $Application1[0].Notes + $this.Input.CMOD.OutdNotes
				$Application1[0].Notes = $NewNotes
				$Application1[0].RebateAmount = $OutdCashForGrass
				$result = $Application1[0].Save()
			
			
			}
			
		}
		"RWPRE" {
		
		}
		"RWREB" {
			$OutdRainwaterRebate = $this.Input.CMOD.OutdRainwaterRebate
			$Application = [AdvancedUtility.Services.BusinessObjects.ConservationApplication]::GetAllWhere($CisSession, "C_account={0} and c_customer={1} and I_ProgramId='25' ORDER BY i_APPLICATIONID desc", $account, $customer) 
			$NewNotes = $Application[0].Notes + $this.Input.CMOD.OutdNotes
			$Application[0].Notes = $NewNotes
			$Application[0].RebateAmount = $OutdRainwaterRebate
			$result = $Application[0].Save()

		}
		"WES" {
		
		}
	}
		
}
Return $True