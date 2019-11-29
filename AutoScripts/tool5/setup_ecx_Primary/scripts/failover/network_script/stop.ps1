#
# Oct 28 2019
#

$hostname = hostname
$VMName = "RouterVM_template"
$primaryHostname =  $env:PRIMARY_HOSTNAME
$primaryIp = $env:PRIMARY_IP_ADDRESS
$secondaryHostname =  $env:SECONDARY_HOSTNAME
$secondaryIp = $env:SECONDARY_IP_ADDRESS
$line = "root@"

if ($hostname -eq $primaryHostname) {
    $line = "root@" + $primaryIp
} elseif ($hostname -eq $secondaryHostname) {
    $line = "root@" + $secondaryIp
}

ssh -q -o StrictHostKeyChecking=no $line "nmcli c down eth1"