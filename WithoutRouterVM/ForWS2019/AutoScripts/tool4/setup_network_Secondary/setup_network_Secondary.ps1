$appVmName = $env:APP_VM_NAME
$vmPubSwitch = "public-network"


Write-Host "Attaching virtual switch to ApplicationVM..."

Connect-VMNetworkAdapter -VMName $appVmName -Name "Network Adapter" -SwitchName $vmPubSwitch

Write-Host "Virtual switch is attached to ApplicationVM."