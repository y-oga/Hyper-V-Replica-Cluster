$ipPub = $env:SECONDARY_IP_ADDRESS_TO_PUB
$product = $env:ECX_OR_CLP

clpcl -r --web --alert
$path = "C:\Program Files\EXPRESSCLUSTER\work"
if ($product -eq "CLP") {
    $path = "C:\Program Files\CLUSTERPRO\work"
}

armem /M reboot

Copy-Item "..\..\tool5\setup_ecx_Primary\trnreq" -Destination $path -Recurse