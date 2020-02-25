#
# Feb 25 2020
#
$monNumber = $env:MONITOR_NUMBER
$returnVal = "RETURNSTART" + $monNumber
armsetcd $returnVal 0

$hostname = hostname
$group = $env:FAILOVER_NAME
$active_srv = clpgrp -n $group

$targetVMName = $env:TARGET_VM_NAME
$primaryHostname =  $env:PRIMARY_HOSTNAME
$secondaryHostname =  $env:SECONDARY_HOSTNAME
$primaryHostIp = $env:PRIMARY_HOST_IP_ADDRESS
$secondaryHostIp = $env:SECONDARY_HOST_IP_ADDRESS
$domain = $env:DOMAIN

#
# If primary server is shutdown and secondary server becomes active server,
# replication is stopped forcibly.
# Get-VMReplication server shows the below value.
# PrimaryServer: crashed server
# ReplicaServer: active server
#
$VMRepInfo = Get-VMReplication -VMName $targetVMName
$mode = $VMRepInfo.Mode
$primaryFQDN = $VMRepInfo.PrimaryServer
$secondaryFQDN = $VMRepInfo.ReplicaServer

if ($domain -eq "hyperv.local") {
    #
    # Get credential information of both servers.
    #
    $tmp = "CN=" + $primaryFQDN
    $tmp = ls cert:\LocalMachine\My | Where-Object {$_.Subject -eq $tmp}
    $primaryThumbprint = $tmp.Thumbprint
    $tmp = "CN=" + $secondaryFQDN
    $tmp = ls cert:\LocalMachine\My | Where-Object {$_.Subject -eq $tmp}
    $secondaryThumbprint = $tmp.Thumbprint
}

#
# Get information of opposite server.
#
$tmpPNameList = $primaryFQDN.Split(".")
$tmpPName = $tmpPNameList[0]
$ownHostname = "null"
$ownFQDN = "null"
$ownIp = "null"
$oppositeHostname = "null"
$oppositeFQDN = "null"
$oppositeIp = "null"
if ($domain -eq "hyperv.local") {
    $ownThumbprint = "null"
    $oppositeThumbprint = "null"
}

if ($tmpPName -eq $primaryHostname) {
    if ($mode -eq "Primary") {
        $ownHostname = $primaryHostname
        $ownFQDN = $primaryFQDN
        $ownIp = $primaryHostIp
        $oppositeHostname = $secondaryHostname
        $oppositeFQDN = $secondaryFQDN
        $oppositeIp = $secondaryHostIp
        if ($domain -eq "hyperv.local") {
            $ownThumbprint = $primaryThumbprint
            $oppositeThumbprint = $secondaryThumbprint
        }
    } else {
        $ownHostname = $secondaryHostname
        $ownFQDN = $secondaryFQDN
        $ownIp = $secondaryHostIp
        $oppositeHostname = $primaryHostname
        $oppositeFQDN = $primaryFQDN
        $oppositeIp = $primaryHostIp
        if ($domain -eq "hyperv.local") {
            $ownThumbprint = $secondaryThumbprint
            $oppositeThumbprint = $primaryThumbprint
        }
    }
} else {
    if ($mode -eq "Primary") {
        $ownHostname = $secondaryHostname
        $ownFQDN = $primaryFQDN
        $ownIp = $secondaryHostIp
        $oppositeHostname = $primaryHostname
        $oppositeFQDN = $secondaryFQDN
        $oppositeIp = $primaryHostIp
        if ($domain -eq "hyperv.local") {
            $ownThumbprint = $primaryThumbprint
            $oppositeThumbprint = $secondaryThumbprint
        }
    } else {
        $ownHostname = $primaryHostname
        $ownFQDN = $secondaryFQDN
        $ownIp = $primaryHostIp
        $oppositeHostname = $secondaryHostname
        $oppositeFQDN = $primaryFQDN
        $oppositeIp = $secondaryHostIp
        if ($domain -eq "hyperv.local") {
            $ownThumbprint = $secondaryThumbprint
            $oppositeThumbprint = $primaryThumbprint
        }
    }
}


try {
    Start-VMFailover -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
} catch {
    $clpmsg = "failover.bat: Start-VMFailover " + $targetVMName + " is failed."
    clplogcmd -m $clpmsg -l ERR
    armsetcd $returnVal 2
    exit 1
}

while ($true) {
    try {
        Start-VM -VMName $targetVMName -Confirm:$False
    } catch {
        $clpmsg = "failover.bat: Start-VM " + $targetVMName + " is failed."
        clplogcmd -m $clpmsg -l ERR
        armsetcd $returnVal 2
        exit 1
    }

    $ownVM = Get-VM -VMName $targetVMName -ComputerName $ownFQDN -ErrorAction stop
    if ($ownVM.State -eq "Running") {
        break
    }
}