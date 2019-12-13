$ecxSilentInstallPath = $env:ECX_PATH + "\Windows\4.1\common\server\x64\silent-install.bat"
$hostnameP = $env:PRIMARY_HOSTNAME
$hostnameS = $env:SECONDARY_HOSTNAME
$ipP = $env:PRIMARY_IP_ADDRESS
$ipS = $env:SECONDARY_IP_ADDRESS
$pw = $env:CERT_FILE_PASSWORD

# Check whether install file exists.
$ret = Test-Path $ecxSilentInstallPath
if ($ret -eq $False) {
    Write-Host ($ecxSilentInstallPath + " does not exist.")
    exit 0
}

# Install Hyper-V
Write-Host "Installing Hyper-V..."
Install-WindowsFeature -Name "Hyper-V" -IncludeManagementTools

# Install EXPRESSCLUSTER
Write-Host "Installing EXPRESSCLUSTER..."
Start-Process $ecxSilentInstallPath -Wait -NoNewWindow

# Change Primary DNS Suffix
Write-Host "Changing Primary DNS Suffix..."
$path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
Set-ItemProperty $path -name "NV Domain" -value "hyperv.local"

# Create Certificate
Write-Host "Creating Certificate..."

# Edit hosts file
$fqdnP = $hostnameP + ".hyperv.local"
$line = $ipP + " " + $fqdnP
Write-Output $line | Add-Content "C:\Windows\System32\drivers\etc\hosts" -Encoding Default
$fqdnS = $hostnameS + ".hyperv.local"
$line = $ipS + " " + $fqdnS
Write-Output $line | Add-Content "C:\Windows\System32\drivers\etc\hosts" -Encoding Default

# Create certificate
New-SelfSignedCertificate -DnsName $fqdnP -CertStoreLocation "cert:\LocalMachine\My" -TestRoot
New-SelfSignedCertificate -DnsName $fqdnS -CertStoreLocation "cert:\LocalMachine\My" -TestRoot

# Export certificate for secondary server
$securepw = ConvertTo-SecureString -String $pw -Force -AsPlainText
$filename = ".\" + $hostnameS + ".hyperv.local.pfx"
$tmp = "CN=" + $hostnameS + ".hyperv.local"
$tmp = ls cert:\LocalMachine\My | Where-Object {$_.Subject -eq $tmp}
$thumbprint = $tmp.Thumbprint
$path = "Cert:\LocalMachine\my\" + $thumbprint
Get-ChildItem -Path $path | Export-PfxCertificate -FilePath $filename -Password $securepw

# Export root certificate
$filename = ".\CertRecTestRoot.cer"
$tmp = "CN=CertReq Test Root, OU=For Test Purposes Only"
$tmp = ls cert:\LocalMachine\CA | Where-Object {$_.Subject -eq $tmp}
$thumbprint = $tmp.Thumbprint
$path = "Cert:\LocalMachine\CA\" + $thumbprint
Get-ChildItem -Path $path | Export-Certificate -FilePath $filename

# Move root certificate to another location
Move-Item -Path $path -Destination "cert:\LocalMachine\Root"

# Reboot
Write-Host "This machine will reboot."
Start-Sleep -s 3
Restart-Computer -Force