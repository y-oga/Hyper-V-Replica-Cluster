$hostnameP = $env:PRIMARY_HOSTNAME
$hostnameS = $env:SECONDARY_HOSTNAME
$pw = $env:CERT_FILE_PASSWORD

# Create Certificate
Write-Host "Creating Certificate..."

$fqdnP = $hostnameP + ".hyperv.local"
$fqdnS = $hostnameS + ".hyperv.local"

# Create certificate
New-SelfSignedCertificate -DnsName $fqdnP -CertStoreLocation "cert:\LocalMachine\My" -TestRoot
New-SelfSignedCertificate -DnsName $fqdnS -CertStoreLocation "cert:\LocalMachine\My" -TestRoot

# Export certificate for primary server
$securepw = ConvertTo-SecureString -String $pw -Force -AsPlainText
$filename = ".\" + $hostnameP + ".hyperv.local.pfx"
$tmp = "CN=" + $hostnameP + ".hyperv.local"
$tmp = ls cert:\LocalMachine\My | Where-Object {$_.Subject -eq $tmp}
$thumbprint = $tmp.Thumbprint
$path = "Cert:\LocalMachine\my\" + $thumbprint
Get-ChildItem -Path $path | Export-PfxCertificate -FilePath $filename -Password $securepw

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