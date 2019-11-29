$lcnsPath = $env:LCNS_PATH
$ipPub = $env:IP_ADDRESS_TO_PUB
$line = "root@" + $ipPub

clplcnsc -i $lcnsPath
clpcl -t -a

clpcfctrl --push -w -x .

clpcl -r --web --alert

Copy-Item ".\trnreq" -Destination "C:\Program Files\CLUSTERPRO\work" -Recurse
ssh -q -o StrictHostKeyChecking=no $line "nmcli c down eth1"
ssh -q -o StrictHostKeyChecking=no $line "nmcli c up eth1"

clpcl -s -a

Write-Host "Starting a cluster."