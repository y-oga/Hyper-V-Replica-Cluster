$ipPub = $env:IP_ADDRESS_TO_PUB

clpcl -r --web --alert
Copy-Item "..\..\tool5\setup_ecx_Primary\trnreq" -Destination "C:\Program Files\CLUSTERPRO\work" -Recurse