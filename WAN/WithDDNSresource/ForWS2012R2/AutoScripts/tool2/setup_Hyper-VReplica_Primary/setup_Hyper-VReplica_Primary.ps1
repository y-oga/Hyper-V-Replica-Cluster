# Feb 19 2020

$hostnameP = $env:PRIMARY_HOSTNAME
$hostnameS = $env:SECONDARY_HOSTNAME
$ipP = $env:PRIMARY_IP_ADDRESS
$ipS = $env:SECONDARY_IP_ADDRESS
$domain = $env:DOMAIN
$pw = $env:CERT_FILE_PASSWORD

$vmNum = $env:APP_VM_NUM
$vmPath = @($env:APP_VM_PATH1,
            $env:APP_VM_PATH2, 
            $env:APP_VM_PATH3, 
            $env:APP_VM_PATH4,
            $env:APP_VM_PATH5,
            $env:APP_VM_PATH6)  
$vmId = @($env:APP_VM_ID1,
          $env:APP_VM_ID2,
          $env:APP_VM_ID3,
          $env:APP_VM_ID4,
          $env:APP_VM_ID5,
          $env:APP_VM_ID6)
$vmName = @($env:APP_VM_NAME1,
            $env:APP_VM_NAME2, 
            $env:APP_VM_NAME3, 
            $env:APP_VM_NAME4,
            $env:APP_VM_NAME5,
            $env:APP_VM_NAME6) 
$vmPubSwitch = "internal-network"

# Check whether VM file exists.
for ($i = 0; $i -lt $vmNum; $i++) {
    $vmcxPath = $vmPath[$i] + "\" + $vmId[$i] + ".xml"
    $ret = Test-Path $vmcxPath
    if ($ret -eq $False) {
        Write-Host ($vmcxPath + " does not exist.")
        exit 0
    }
}

if ($domain -eq "hyperv.local") {
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
}

# Import ApplicationVM
for ($i = 0; $i -lt $vmNum; $i++) {
    $vmcxPath = $vmPath[$i] + "\" + $vmId[$i] + ".xml"
    Import-VM -Path $vmcxPath -Confirm:$False
    Write-Host ($vmName[$i] + " has been imported successfully.")
}

# Change ApplicationVM setting
for ($i = 0; $i -lt $vmNum; $i++) {
    Set-VM -Name $vmName[$i] -AutomaticStartAction "Nothing"
}

# Create Virtual Switches
New-VMSwitch -name $vmPubSwitch -SwitchType "Internal"

# Attach virtual switched to RouterVM and ApplicationVM
for ($i = 0; $i -lt $vmNum; $i++) {
    Connect-VMNetworkAdapter -VMName $vmName[$i] -Name "Network Adapter" -SwitchName $vmPubSwitch
}