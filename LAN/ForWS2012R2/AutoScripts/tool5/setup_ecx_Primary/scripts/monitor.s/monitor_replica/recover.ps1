#
# Dec 26 2019
#

$hostname = hostname
$group = $env:FAILOVER_NAME
$active_srv = clpgrp -n $group

#
# This script is executed only on active server.
#
if ($hostname -ne $active_srv) {
    exit 0
}

$targetVMName = $env:TARGET_VM_NAME
$primaryHostname =  $env:PRIMARY_HOSTNAME
$secondaryHostname =  $env:SECONDARY_HOSTNAME
$primaryHostIp = $env:PRIMARY_HOST_IP_ADDRESS
$secondaryHostIp = $env:SECONDARY_HOST_IP_ADDRESS

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

#
# Get credential information of both servers.
#
$tmp = "CN=" + $primaryFQDN
$tmp = ls cert:\LocalMachine\My | Where-Object {$_.Subject -eq $tmp}
$primaryThumbprint = $tmp.Thumbprint
$tmp = "CN=" + $secondaryFQDN
$tmp = ls cert:\LocalMachine\My | Where-Object {$_.Subject -eq $tmp}
$secondaryThumbprint = $tmp.Thumbprint

#
# Get information of opposite server.
#
$tmpPNameList = $primaryFQDN.Split(".")
$tmpPName = $tmpPNameList[0]
$ownHostname = "null"
$ownFQDN = "null"
$ownIp = "null"
$ownThumbprint = "null"
$oppositeHostname = "null"
$oppositeFQDN = "null"
$oppositeIp = "null"
$oppositeThumbprint = "null"

if ($tmpPName -eq $primaryHostname) {
    if ($mode -eq "Primary") {
        $ownHostname = $primaryHostname
        $ownFQDN = $primaryFQDN
        $ownIp = $primaryHostIp
        $ownThumbprint = $primaryThumbprint
        $oppositeHostname = $secondaryHostname
        $oppositeFQDN = $secondaryFQDN
        $oppositeIp = $secondaryHostIp
        $oppositeThumbprint = $secondaryThumbprint
    } else {
        $ownHostname = $secondaryHostname
        $ownFQDN = $secondaryFQDN
        $ownIp = $secondaryHostIp
        $ownThumbprint = $secondaryThumbprint
        $oppositeHostname = $primaryHostname
        $oppositeFQDN = $primaryFQDN
        $oppositeIp = $primaryHostIp
        $oppositeThumbprint = $primaryThumbprint
    }
} else {
    if ($mode -eq "Primary") {
        $ownHostname = $secondaryHostname
        $ownFQDN = $primaryFQDN
        $ownIp = $secondaryHostIp
        $ownThumbprint = $primaryThumbprint
        $oppositeHostname = $primaryHostname
        $oppositeFQDN = $secondaryFQDN
        $oppositeIp = $primaryHostIp
        $oppositeThumbprint = $secondaryThumbprint
    } else {
        $ownHostname = $primaryHostname
        $ownFQDN = $secondaryFQDN
        $ownIp = $primaryHostIp
        $ownThumbprint = $secondaryThumbprint
        $oppositeHostname = $secondaryHostname
        $oppositeFQDN = $primaryFQDN
        $oppositeIp = $secondaryHostIp
        $oppositeThumbprint = $primaryThumbprint
    }
}
#
# Check if opposite returns to a cluster.
#
$ret = ping $oppositeIp
if ($? -eq $False) {
    exit 0
}

#
# Check if cluster service is running on opposite server.
#
$ret = clprexec --script "check.bat" -h $oppositeIp
if ($? -eq $False) {
    exit 0
}

#
# Recovery process
#
$status_ok_count = 0
$status_error_count = 0
while (1) {
    #
    # If "Replicating" status (fine status) is repeated twice, this monitor script exits.
    #
    if ($status_ok_count -eq 2) {
        exit 0
    }

    #
    # In each roop, get Hyper-V Replica status, and branch off depending the status.
    # This script will be executed while both servers are running.
    #
    try {
        $ownRep = Get-VMReplication -VMName $targetVMName -ComputerName $ownFQDN -ErrorAction stop
        $oppRep = Get-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN -ErrorAction stop
        $ownVM = Get-VM -VMName $targetVMName -ComputerName $ownFQDN -ErrorAction stop
        $oppVM = Get-VM -VMName $targetVMName -ComputerName $oppositeFQDN -ErrorAction stop
    } catch {
        exit 0
    }

    if (($ownRep.State -eq "Replicating") -And ($oppRep.State -eq "Replicating")) {
        $status_ok_count = $status_ok_count + 1

        #
        # If VM is Off or Saved, turn on the VM.
        #
        if ($ownRep.Mode -eq "Primary") {
            if (($ownVM.State -eq "Off") -Or ($ownVM.State -eq "Saved") -Or ($ownVM.State -eq "Paused")) {
                try {
                    Start-VM -Name $targetVMName -Confirm:$False
                } catch {
                    exit 1
                }
            }
        } elseif ($ownRep.Mode -eq "Replica") {
            if (($oppVM.State -eq "Off") -Or ($oppVM.State -eq "Saved") -Or ($oppVM.State -eq "Paused")) {
                try {
                    Start-VM -Name $targetVMName -ComputerName $oppositeFQDN -Confirm:$False
                } catch {
                    exit 1
                }
            }
        }
        
        #
        # If a failover group and a target VM are running in separate servers,
        # move the falover group to another server.
        # Start.bat does nothing if Replica status is "Replicating" on both servers.
        #
        if ($ownRep.Mode -eq "Replica") {
            clpgrp -m
        }

        continue
    }

    if (($ownRep.State -eq "Suspended") -And ($ownRep.Mode -eq "Primary")) {
        Resume-VMReplication -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
    }
    if (($oppRep.State -eq "Suspended") -And ($oppRep.Mode -eq "Primary")) {
        Resume-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN -Confirm:$False
    }

    if ($ownRep.State -eq "FailedOverWaitingCompletion") {
        #
        # This scope is executed only on Replica server.
        # FailedOverWaitingCompletion is seen only on Replica server.
        #
        if ($oppRep.State -eq "Error") {
            #
            # OS shutdown scenario STEP 1/4
            #
            if ($oppVM.State -ne "Off") {
                try {
                    Remove-VMSavedState -VMName $targetVMName -ComputerName $oppositeFQDN -Confirm:$False
                } catch {
                    exit 1
                }
            }
            #
            # OS shutdown scenario STEP 2/4
            #
            try {
                clprexec --script "recover.bat" -h $oppositeIp
            } catch {
                exit 1
            }

            while (1) {
                $oppRep = Get-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN
                if ($oppRep.State -eq "WaitingForInitialReplication") {
                    break
                }
            }
        } elseif ($oppRep.State -eq "WaitingForStartResynchronize") {
            #
            # Forced termination scenario STEP 1/3
            #
            # Recover.bat changes the Replica status of opposite server
            # from Primary to Replica.
            #
            try {
                clprexec --script "recover.bat" -h $oppositeIp
            } catch {
                exit 1
            }

            while (1) {
                $oppRep = Get-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN
                if ($oppRep.State -eq "WaitingForInitialReplication") {
                    break
                }
            }
        } elseif ($oppRep.State -eq "WaitingForInitialReplication") {
            #
            # Forced termination scenario STEP 2/3
            # OS shutdown scenario STEP 3/4
            #
            try {
                Set-VMReplication -VMName $targetVMName -Reverse -ReplicaServerName $oppositeFQDN -ComputerName $ownFQDN -AuthenticationType "Certificate" -CertificateThumbprint $ownThumbprint -Confirm:$False
            } catch {
                exit 1
            }

            while (1) {
                $ownRep = Get-VMReplication -VMName $targetVMName -ComputerName $ownFQDN
                if ($ownRep.State -eq "ReadyForInitialReplication") {
                    break
                }
            }
        } elseif ($oppRep.State -eq "PreparedForFailover") {
            #
            # When failover fails 1/2
            #
            try {
                Complete-VMFailover -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
            } catch {
                exit 1
            }
        }
    } elseif ($ownRep.State -eq "ReadyForInitialReplication") {
        if ($oppRep.State -eq "WaitingForInitialReplication") {
            #
            # Forced termination scenario STEP 3/3
            # OS shutdown scenario STEP 4/4
            #
            try {
                Start-VMInitialReplication -VMName $targetVMName -ComputerName $ownFQDN
            } catch {
                exit 1
            }

            while (1) {
                $ownRep = Get-VMReplication -VMName $targetVMName
                sleep -s 5
                if ($ownRep.State -eq "Replicating") {
                    break
                }
            }
        }
    } elseif ($ownRep.State -eq "Error") {
        if ($oppRep.State -eq "Replicating") {
            #
            # Both server's OS shutdown
            #
            try {
                Resume-VMReplication -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
            } catch {
                exit 1
            }
        } else {
            #
            # Split brain CASE1
            #

            #
            # Exclude Split brain CASE2
            #
            try {
                $ownVM = Get-VM -VMName $targetVMName -ComputerName $ownFQDN -ErrorAction stop
                $oppVM = Get-VM -VMName $targetVMName -ComputerName $oppositeFQDN -ErrorAction stop
            } catch {
                exit 0
            }
            if (($ownVM.State -eq "Running") -And ($oppVM.State -eq "Running")) {
                continue
            }

            if ($oppVM.State -ne "Off") {
                try {
                    Remove-VMSavedState -VMName $targetVMName -ComputerName $oppositeFQDN -Confirm:$False
                } catch {
                    exit 1
                }
            }
            try {
                Stop-VMFailover -VMName $targetVMName -ComputerName $oppositeFQDN -Confirm:$False
            } catch {
                exit 1
            }
        }
    } elseif ($ownRep.State -eq "Replicating") {
        if ($oppRep.State -eq "Error") {
            #
            # OS shutdown scenario STEP 2/2
            #
            
            #
            # If opposite VM is Saved, start the VM.
            #
            if ($oppVM.State -eq "Saved") {
                try {
                    Start-VM -Name $targetVMName -ComputerName $oppositeFQDN -Confirm:$False
                } catch {
                    exit 1
                }
            }
            
            try {
                Resume-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN -Confirm:$False
            } catch {
                exit 1
            }

            #
            # Split brain CASE 2 1/2
            # Resume-VMReplication does not work.
            # Reverse replication dirrection.
            #
            if ($status_error_count -gt 0) {
                if ($oppVM.State -eq "Running") {
                    try {
                        Stop-VM -Name $targetVMName -ComputerName $oppositeFQDN -Confirm:$False -Force
                    } catch {
                        exit 1
                    }
                }

                try {
                    clprexec --script "recover.bat" -h $oppositeIp
                } catch {
                    exit 1
                }
                
                while (1) {
                    $oppRep = Get-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN
                    if ($oppRep.State -eq "WaitingForInitialReplication") {
                        break
                    }
                }
            }

            $status_error_count = $status_error_count + 1
        } elseif ($oppRep.State -eq "WaitingForInitialReplication") {
            #
            # Split brain CASE 2 2/2
            #
            try {
                Start-VMFailover -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
            } catch {
                exit 1
            }
        } elseif ($oppRep.State -eq "WaitingForStartResynchronize") {
            #
            # Both server's forced termination scenario
            #
            try {
                clprexec --script "recover.bat" -h $oppositeIp
            } catch {
                exit 1
            }

            while (1) {
                $oppRep = Get-VMReplication -VMName $targetVMName -ComputerName $oppositeFQDN
                if ($oppRep.State -eq "WaitingForInitialReplication") {
                    break
                }
            }
        }
    } elseif ($ownRep.State -eq "WaitingForInitialReplication") {
        if ($oppRep.State -eq "Replicating") {
            #
            # Both server's forced termination scenario
            #
            try {
                Resume-VMReplication -VMName $targetVMName -ComputerName $ownFQDN -Confirm:$False
            } catch {
                exit 1
            }
        }
    } elseif ($ownRep.State -eq "WaitingForStartResynchronize") {
        #
        # Both server's forced termination scenario
        #
        try {
            Resume-VMReplication -VMName $targetVMName -ComputerName $ownFQDN -Resynchronize -Confirm:$False
        } catch {
            exit 1
        }
    } elseif ($ownRep.State -eq "FailedOver") {
        if ($oppRep.State -eq "PreparedForFailover") {
            #
            # When failover fails 2/2
            #
            try {
                Set-VMReplication -VMName $targetVMName -Reverse -ReplicaServerName $oppositeFQDN -ComputerName $ownFQDN -AuthenticationType "Certificate" -CertificateThumbprint $ownThumbprint -Confirm:$False
            } catch {
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
        # If there are any other patterns, please add new IF
        #
        exit 0
    }
}

