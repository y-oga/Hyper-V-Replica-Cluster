$hostnameP = $env:PRIMARY_HOSTNAME
$hostnameS = $env:SECONDARY_HOSTNAME
$ipP = $env:PRIMARY_IP_ADDRESS
$ipS = $env:SECONDARY_IP_ADDRESS

$vmName = $env:APP_VM_NAME

# Start VM replication
$fqdnP = $hostnameP + ".hyperv.local"
$fqdnS = $hostnameS + ".hyperv.local"
$tmp = "CN=" + $fqdnP
$tmp = ls cert:\LocalMachine\My | Where-Object {$_.Subject -eq $tmp}
$thumbprint = $tmp.Thumbprint
Enable-VMReplication -VMName $vmName -ReplicaServerName $fqdnS -ReplicaServerPort 443 -ReplicationFrequencySec 30 -AuthenticationType "Certificate" -CertificateThumbprint $thumbprint -Confirm:$False
Start-VMInitialReplication -VMName $vmName