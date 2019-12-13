#
# Oct 28 2019
#

$group = $env:FAILOVER_NAME
$active_srv = clpgrp -n $group
$host_name = hostname
if ($host_name -eq $active_srv) {
    exit 0
}

$VMName = "RouterVM_template"
$primaryHostname =  $env:PRIMARY_HOSTNAME
$primaryIp = $env:PRIMARY_IP_ADDRESS
$secondaryHostname =  $env:SECONDARY_HOSTNAME
$secondaryIp = $env:SECONDARY_IP_ADDRESS

if ($host_name -eq $primaryHostname) {
    $line = "root@" + $primaryIp
} elseif ($host_name -eq $secondaryHostname) {
    $line = "root@" + $secondaryIp
}

ssh -t $line "nmcli c down eth1"
