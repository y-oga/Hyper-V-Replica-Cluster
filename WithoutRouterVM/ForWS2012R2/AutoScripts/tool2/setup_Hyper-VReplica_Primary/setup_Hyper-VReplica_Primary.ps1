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
$vmcxPath = $vmPath + "\" + $vmId + ".xml"
$ret = Test-Path $vmcxPath
if ($ret -eq $False) {
    Write-Host ($vmcxPath + " does not exist.")
    exit 0
}

# Check whether certificate exists.
$path = ".\" + $hostnameP + ".hyperv.local.pfx"
$ret = Test-Path $path
if ($ret -eq $False) {
    Write-Host ($path + " does not exist.")
    exit 0
}
$path = ".\CertRecTestRoot.cer"
$ret = Test-Path $path
if ($ret -eq $False) {
    Write-Host ($path + " does not exist.")
    exit 0
}

# Start setting up Hyper-V Replica
Write-Host "Importing certificate..."

# Import root certificate
$filename = ".\CertRecTestRoot.cer"
$path = "Cert:\LocalMachine\Root"
Import-Certificate -FilePath $filename -CertStoreLocation $path

# Import server certificate
$securepw = ConvertTo-SecureString -String $pw -Force -AsPlainText
$filename = ".\" + $hostnameP + ".hyperv.local.pfx"
$path = "Cert:\LocalMachine\my"
Import-PfxCertificate -FilePath $filename -CertStoreLocation $path -Password $securepw

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