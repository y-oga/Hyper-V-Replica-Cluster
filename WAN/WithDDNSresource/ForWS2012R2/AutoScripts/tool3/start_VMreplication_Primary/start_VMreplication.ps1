$hostnameP = $env:PRIMARY_HOSTNAME
$hostnameS = $env:SECONDARY_HOSTNAME
$ipP = $env:PRIMARY_IP_ADDRESS
$ipS = $env:SECONDARY_IP_ADDRESS

$vmNum = $env:APP_VM_NUM
$vmName = @($env:APP_VM_NAME1,
            $env:APP_VM_NAME2, 
            $env:APP_VM_NAME3, 
            $env:APP_VM_NAME4,
            $env:APP_VM_NAME5,
            $env:APP_VM_NAME6)

# Start VM replication
$fqdnP = $hostnameP + ".hyperv.local"
$fqdnS = $hostnameS + ".hyperv.local"
$tmp = "CN=" + $fqdnP
$tmp = ls cert:\LocalMachine\My | Where-Object {$_.Subject -eq $tmp}
$thumbprint = $tmp.Thumbprint
for ($i = 0; $i -lt $vmNum; $i++) {
    Enable-VMReplication -VMName $vmName[$i] -ReplicaServerName $fqdnS -ReplicaServerPort 443 -ReplicationFrequencySec 30 -AuthenticationType "Certificate" -CertificateThumbprint $thumbprint -Confirm:$False
    Start-VMInitialReplication -VMName $vmName[$i]
}