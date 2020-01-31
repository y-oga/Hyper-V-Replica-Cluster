$lcnsPath = $env:LCNS_PATH
$product = $env:ECX_OR_CLP
$pHostname = $env:PRIMARY_HOSTNAME
$pIp = $env:PRIMARY_IP_ADDRESS
$sHostname = $env:SECONDARY_HOSTNAME
$sIp = $env:SECONDARY_IP_ADDRESS
$targetVM = $env:APP_VM_NAME
$adminPass = $env:ADMIN_PASS

$pHostname = $pHostname.ToLower()
$sHostname = $sHostname.ToLower()

$path = ".\scripts\failover\replica_script\cluster_config.bat"
$file_contents = $(Get-Content $path) -creplace "INPUT_PRIMARY_HOSTNAME",$pHostname
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte
$file_contents = $(Get-Content $path) -creplace "INPUT_PRIMARY_HOST_IP_ADDRESS",$pIp
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte
$file_contents = $(Get-Content $path) -creplace "INPUT_SECONDARY_HOSTNAME",$sHostname
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte
$file_contents = $(Get-Content $path) -creplace "INPUT_SECONDARY_HOST_IP_ADDRESS",$sIp
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte
$file_contents = $(Get-Content $path) -creplace "INPUT_TARGET_VM_NAME",$targetVM
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte


$path = ".\clp.conf"
$file_contents = $(Get-Content $path) -creplace "INPUT_PASS",$adminPass
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte
$file_contents = $(Get-Content $path) -creplace "INPUT_HOST1",$pHostname.ToLower()
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte
$file_contents = $(Get-Content $path) -creplace "INPUT_IP1",$pIp
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte
$file_contents = $(Get-Content $path) -creplace "INPUT_HOST2",$sHostname.ToLower()
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte
$file_contents = $(Get-Content $path) -creplace "INPUT_IP2",$sIp
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $path -Encoding Byte

$line = "root@" + $prIp

clplcnsc -i $lcnsPath
clpcl -t -a

clpcfctrl --push -w -x .

clpcl -r --web --alert

$path = "C:\Program Files\EXPRESSCLUSTER\work"
if ($product -eq "CLP") {
    $path = "C:\Program Files\CLUSTERPRO\work"
}
Copy-Item ".\trnreq" -Destination $path -Recurse

clpcl -s -a

armem /M reboot

Write-Host "Starting a cluster."