# Feb 19 2020

$vmNum = $env:APP_VM_NUM
$appVmName = @($env:APP_VM_NAME1,
            $env:APP_VM_NAME2, 
            $env:APP_VM_NAME3, 
            $env:APP_VM_NAME4,
            $env:APP_VM_NAME5,
            $env:APP_VM_NAME6)
$vmPubSwitch = "internal-network"


Write-Host "Attaching virtual switch to ApplicationVM..."
for ($i = 0; $i -lt $vmNum; $i++) {
    Connect-VMNetworkAdapter -VMName $appVmName[$i] -Name "Network Adapter" -SwitchName $vmPubSwitch
}
Write-Host "Virtual switch is attached to ApplicationVM."