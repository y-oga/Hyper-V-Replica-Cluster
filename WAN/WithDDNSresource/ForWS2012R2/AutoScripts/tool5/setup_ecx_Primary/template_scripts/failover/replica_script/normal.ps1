#
# Feb 25 2020
#
$monNumber = $env:MONITOR_NUMBER
$returnVal = "RETURNSTART" + $monNumber
armsetcd $returnVal 1

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

$ownRep = Get-VMReplication -VMName $targetVMName -ComputerName $ownFQDN
try {
    $oppRep = Get-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN -ErrorAction stop
} catch {
    #
    # Only this server starts up after both server's forced termination
    #
    if ($ownRep.Mode -eq "Primary") {
        Start-VM -VMName $targetVMName -Confirm:$False
        exit 0
    } elseif ($ownRep.Mode -eq "Replica") {
        if ($ownRep.State -ne "FailedOverWaitingCompletion") {
            try {
                Start-VMFailover -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
            } catch {
                $clpmsg = "start.bat: Start-VMFailover " + $targetVMName + " is failed."
                clplogcmd -m $clpmsg -l ERR
                armsetcd $returnVal 2
                exit 1
            }
        }

        while ($true) {
            try {
                Start-VM -VMName $targetVMName -Confirm:$False
            } catch {
                $clpmsg = "start.bat: Start-VM " + $targetVMName + " is failed."
                clplogcmd -m $clpmsg -l ERR
                armsetcd $returnVal 2
                exit 1
            }
            $ownVM = Get-VM -Name $targetVMName
            if ($ownVM.State -eq "Running") {
                exit 0
            }
        }
    }
}
if (($ownRep.State -eq "Replicating") -And ($oppRep.State -eq "Replicating") -And ($ownRep.Mode -eq "Primary")) {
    while ($true) {
        try {
            Start-VM -VMName $targetVMName -Confirm:$False
        } catch {
            $clpmsg = "start.bat: Start-VM " + $targetVMName + " is failed."
            clplogcmd -m $clpmsg -l ERR
            armsetcd $returnVal 2
            exit 1
        }
        $ownVM = Get-VM -Name $targetVMName
        if ($ownVM.State -eq "Running") {
            exit 0
        }
    }
}

#
# Reverse replication
#
while (1) {
    #
    # In each roop, get Hyper-V Replica status, and branch off depending the status.
    #
    $ownRep = Get-VMReplication -VMName $targetVMName
    $oppRep = Get-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN
    $ownVM = Get-VM -Name $targetVMName
    $oppVM = Get-VM -Name $targetVMName -ComputerName $oppositeFQDN
    #
    # If opposite VM is running, turn off it.
    #
    if (($oppRep.Mode -eq "Primary") -And ($oppVM.State -eq "Running")) {
        try {
            Stop-VM $targetVMName -ComputerName $oppositeFQDN -Confirm:$False -Force
        } catch {
            $clpmsg = "start.bat: Stop-VM " + $targetVMName + " is failed on " + $oppositeHostname + "."
            clplogcmd -m $clpmsg -l ERR
            armsetcd $returnVal 2
            exit 1
        }
        while (1) {
            $oppVM = Get-VM -Name $targetVMName -ComputerName $oppositeFQDN
            if ($oppVM.State -eq "Off") {
                break
            }
        }
    }

    if ($ownRep.State -eq "Replicating") {
        if ($oppRep.State -eq "Replicating") {
            if ($ownRep.Mode -eq "Primary") {
                if ($ownVM.State -eq "Off") {
                    #
                    # Failover STEP 5/5
                    #
                    while ($true) {
                        try {
                            Start-VM -VMName $targetVMName -Confirm:$False
                        } catch {
                            $clpmsg = "start.bat: Start-VM " + $targetVMName + " is failed."
                            clplogcmd -m $clpmsg -l ERR
                            armsetcd $returnVal 2
                            exit 1
                        }
                        $ownVM = Get-VM -Name $targetVMName
                        if ($ownVM.State -eq "Running") {
                            exit 0
                        }
                    }
                }
                #
                # Failover has been completed.
                #
                exit 0
            } elseif ($ownRep.Mode -eq "Replica") {
                #
                # Failover STEP 1/5
                #
                try {
                    Start-VMFailover -VMName $targetVMName -ComputerName $oppositeFQDN -Prepare -Confirm:$False
                } catch {
                    $clpmsg = "start.bat: Start-VMFailover " + $targetVMName + " is failed."
                    clplogcmd -m $clpmsg -l ERR
                    armsetcd $returnVal 2
                    exit 1
                }
            }
        } elseif ($oppRep.State -eq "PreparedForFailover") {
            #
            # Failover STEP 2/5
            #
            try {
                Start-VMFailover -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
            } catch {
                $clpmsg = "start.bat: Start-VMFailover " + $targetVMName + " is failed."
                clplogcmd -m $clpmsg -l ERR
                armsetcd $returnVal 2
                exit 1
            }
        } elseif ($oppRep.State -eq "WaitingForStartResynchronize") {
            #
            # Both server's forced termination STEP 1/
            # monitor_replica will execute recovery process
            #
            exit 0
        }
    } elseif ($ownRep.State -eq "FailedOverWaitingCompletion") {
        if ($oppRep.State -eq "PreparedForFailover") {
            #
            # Failover STEP 3/5
            #
            try {
                Complete-VMFailover -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
            } catch {
                $clpmsg = "start.bat: Complete-VMFailover " + $targetVMName + " is failed."
                clplogcmd -m $clpmsg -l ERR
                armsetcd $returnVal 2
                exit 1
            }
        }
    } elseif ($ownRep.State -eq "FailedOver") {
        if ($oppRep.State -eq "PreparedForFailover") {
            #
            # Failover STEP 4/5
            #
            try {
                if ($domain -eq "hyperv.local") {
                    Set-VMReplication -VMName $targetVMName -Reverse -ReplicaServerName $oppositeFQDN -ComputerName $ownFQDN -AuthenticationType "Certificate" -CertificateThumbprint $ownThumbprint -Confirm:$False
                } else {
                    Set-VMReplication -VMName $targetVMName -Reverse -ReplicaServerName $oppositeFQDN -ComputerName $ownFQDN -AuthenticationType "Kerberos" -Confirm:$False
                }
            } catch {
                $clpmsg = "start.bat: Set-VMReplication -Reverse " + $targetVMName + " is failed."
                clplogcmd -m $clpmsg -l ERR
                armsetcd $returnVal 2
                exit 1
            }

            while (1) {
                $ownRep = Get-VMReplication -VMName $targetVMName
                if ($ownRep.Mode -eq "Primary") {
                    break
                }
            }
        }
    } else {
        #
        # monitor_replica executes recovery process
        #
        exit 0
    }
}