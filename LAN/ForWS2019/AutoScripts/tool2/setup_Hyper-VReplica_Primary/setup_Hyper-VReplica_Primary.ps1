$hostnameP = $env:PRIMARY_HOSTNAME
$hostnameS = $env:SECONDARY_HOSTNAME
$ipP = $env:PRIMARY_IP_ADDRESS
$ipS = $env:SECONDARY_IP_ADDRESS
$pw = $env:CERT_FILE_PASSWORD
$vmPath = $env:APP_VM_PATH
$vmId = $env:APP_VM_ID
$vmName = $env:APP_VM_NAME
$vmPubSwitch = "public-network"

# Check whether VM file exists.
$vmcxPath = $vmPath + "\" + $vmId + ".vmcx"
$ret = Test-Path $vmcxPath
if ($ret -eq $False) {
    Write-Host ($vmcxPath + " does not exist.")
    exit 0
}

# Change registry of certificate expiration
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Replication" /v DisableCertRevocationCheck /d 1 /t REG_DWORD /f

# Change WinRM setting
$fqdnS = $hostnameS + ".hyperv.local"
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $fqdnS -Force

# Import ApplicationVM
Import-VM -Path $vmcxPath -Confirm:$False
Write-Host ($vmName + " has been imported successfully.")

# Change ApplicationVM setting
Set-VM -Name $vmName -AutomaticStartAction "Nothing"

# Create Virtual Swithies
New-VMSwitch -name $vmPubSwitch -NetAdapterName "Ethernet" -AllowManagementOS $true

# Attach virtual switched to RouterVM and ApplicationVM
Connect-VMNetworkAdapter -VMName $vmName -Name "Network Adapter" -SwitchName $vmPubSwitch