$accountService = $this.BillService.ServiceId_Lookup

$params = [AdvancedUtility.Services.BusinessObjects.AccountService+GetEstimateParams]::New()
$params.Source = [AdvancedUtility.Services.BusinessObjects.AccountService+EstimateSource]::Bill
$params.CurrentBill = $this.Bill
$params.BillFrequency = $this.Bill.BillFrequency
$params.DegreeDays = $this.Bill.BillEnv.DegreeDays
$params.CustomerAccountInq = $this.CustAcctInq
$params.Customer = $this.CustAcctInq.CustomerAccount.Customer
$params.AccountType = $this.CustAcctInq.CustomerAccount.AccountType
$params.Company = $this.CustAcctInq.CustomerAccount.Company
$params.Division = $this.CustAcctInq.CustomerAccount.Division
$params.ReturnType = [AdvancedUtility.Services.BusinessObjects.AccountService+EstimateReturnType]::Consumption
$params.EstimateMethod = '_1_'
$params.EstimateDate = $this.BillRate.ToDate
$params.Days = $this.BillRate.Days

if ($this.BillReading -ne $null) {
    $params.Meter = $this.BillReading.Meter
    $params.ReadType = $this.BillReading.ReadType
    $params.ReadTypeId = $this.BillReading.ReadTypeId
    $params.PreviousReading = $this.BillReading.PreviousReading
}

$ret = 0
$estimateResult = $accountService.GetEstimate($params)
if ($estimateResult.estimatedOK) {
    $ret = $estimateResult.returnValue
}
else {
    $params.EstimateMethod = '_2_'
    $estimateResult = $accountService.GetEstimate($params)
    if ($estimateResult.estimatedOK) {
        $ret = $estimateResult.returnValue
    }
    else {
        $ret = $null
    }
}

return $ret