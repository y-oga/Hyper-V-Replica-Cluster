# Feb 19 2020

$hostnameP = $env:PRIMARY_HOSTNAME
$hostnameS = $env:SECONDARY_HOSTNAME
$ipP = $env:PRIMARY_IP_ADDRESS
$ipS = $env:SECONDARY_IP_ADDRESS
$domain = $env:DOMAIN
$pw = $env:CERT_FILE_PASSWORD
$vmPubSwitch = "internal-network"

if ($domain -eq "hyperv.local") {
    # Check whether certificate exists.
    $path = ".\" + $hostnameS + ".hyperv.local.pfx"
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
    $filename = ".\" + $hostnameS + ".hyperv.local.pfx"
    $path = "Cert:\LocalMachine\my"
    Import-PfxCertificate -FilePath $filename -CertStoreLocation $path -Password $securepw

    # Change registry of certificate expiration
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Replication" /v DisableCertRevocationCheck /d 1 /t REG_DWORD /f

    # Change WinRM setting
    $fqdnP = $hostnameP + ".hyperv.local"
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $fqdnP -Force
}

# Create Virtual Switches
New-VMSwitch -name $vmPubSwitch -SwitchType "Internal"