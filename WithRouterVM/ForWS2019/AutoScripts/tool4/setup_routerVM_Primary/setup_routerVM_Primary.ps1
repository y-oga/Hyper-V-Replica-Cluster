function read_kvp ($key, $vmName) {
    $filter  = "ElementName = '$vmName'"
    $vm = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter $filter 
    try {
        $ret = $vm.GetRelated("Msvm_KvpExchangeComponent").GuestExchangeItems | % { `   
            $GuestExchangeItemXml = ([XML]$_).SelectSingleNode(`   
                "/INSTANCE/PROPERTY[@NAME='Name']/VALUE[child::text() = '$key']")  
            if ($GuestExchangeItemXml -ne $null)   
            {   
                $GuestExchangeItemXml.SelectSingleNode(`   
                    "/INSTANCE/PROPERTY[@NAME='Data']/VALUE/child::text()").Value   
            }   
        }
    } catch {
        return $null
    }

    return $ret
}

function create_kvp ($key, $value, $vmName) {
    $filter  = "ElementName = '$vmName'"
    $VmMgmt = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService  
    $vm = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter $filter
    $kvpDataItem = ([WMIClass][String]::Format("\\{0}\{1}:{2}", `   
        $VmMgmt.ClassPath.Server, `   
        $VmMgmt.ClassPath.NamespacePath, `   
        "Msvm_KvpExchangeDataItem")).CreateInstance()  
  
    $kvpDataItem.Name = $key
    $kvpDataItem.Data = $value
    $kvpDataItem.Source = 0  
  
    $VmMgmt.AddKvpItems($Vm, $kvpDataItem.PSBase.GetText(1))
    return 0
}

function modify_kvp ($key, $value, $vmName) {
    $filter  = "ElementName = '$vmName'"
    $VmMgmt = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService  
    $vm = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter $filter
    $kvpDataItem = ([WMIClass][String]::Format("\\{0}\{1}:{2}", `   
        $VmMgmt.ClassPath.Server, `   
        $VmMgmt.ClassPath.NamespacePath, `   
        "Msvm_KvpExchangeDataItem")).CreateInstance()  
  
    $kvpDataItem.Name = $key
    $kvpDataItem.Data = $value
    $kvpDataItem.Source = 0  
  
    $VmMgmt.ModifyKvpItems($Vm, $kvpDataItem.PSBase.GetText(1))
    return 0
}

function delete_kvp ($key, $vmName) {
    $filter  = "ElementName = '$vmName'"
    $VmMgmt = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService  
    $vm = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter $filter 
    $kvpDataItem = ([WMIClass][String]::Format("\\{0}\{1}:{2}", `   
        $VmMgmt.ClassPath.Server, `   
        $VmMgmt.ClassPath.NamespacePath, `   
        "Msvm_KvpExchangeDataItem")).CreateInstance()  
  
    $kvpDataItem.Name = $key  
    $kvpDataItem.Data = [String]::Empty   
    $kvpDataItem.Source = 0  
  
    $VmMgmt.RemoveKvpItems($Vm,   
    $kvpDataItem.PSBase.GetText(1))
}





##### Main
$validationFlag = $True
$vmName = "RouterVM_template"
$vmPath = $env:ROUTER_VM_PATH
$vmId = $env:ROUTER_VM_ID
$vmcxPath = $vmPath + "\" + $vmId + ".vmcx"
#$vmPubSwitch = $env:VM_SWITCH_PUB_NAME
#$vmAppSwitch = $env:VM_SWITCH_APP_NAME
$vmPubSwitch = "public-network"
$vmAppSwitch = "application-network"
$vmPubNICTemplate = "NIC to public"
$vmAppNICTemplate = "NIC to application"
$vmNIC0MAC = "null"
$vmNIC1MAC = "null"
$pubMAC = "null"
$appMAC = "null"
$ipPub = $env:PRIMARY_IP_ADDRESS_TO_PUB
$netPub = $env:PRIMARY_NETWORK_OF_PUB
$ipPubSubnet = $env:PRIMARY_SUBNET_PUB
$ipApp = $env:PRIMARY_IP_ADDRESS_TO_APP
$netApp = $env:PRIMARY_NETWORK_OF_APP
$ipAppSubnet = $env:PRIMARY_SUBNET_APP
$ipDns = $env:PRIMARY_IP_ADDRESS_TO_DNS
$ipGateway = $env:PRIMARY_IP_ADDRESS_TO_GATEWAY
$keyList = @("init", "key", "NIC0MAC", "NIC1MAC", "ipPub", "netPub", "ipApp", "netApp", "ipDns", "ipGateway", "ip", "MAC");


##### Validation check
Write-Host "Validation Checking..."

$ret = Test-Path $vmPath
if ($ret -eq $False) {
    Write-Host "VM_PATH does not exist."
    Write-Host ("VM_PATH: " + $vmPath)
    $validationFlag = $False
} else {
    $ret = Test-Path $vmcxPath
    if ($ret -eq $False) {
        Write-Host "VM_ID is wrong or vmcx file does not exist."
        Write-Host ("VM_ID: " + $vmId)
        $validationFlag = $False
    }
}

<#
$ret = Get-VMSwitch | Where-Object {$_.Name -eq $vmPubSwitch}
if ($ret -eq $null) {
    Write-Host "VM_SWITCH_PUB_NAME does not exist."
    Write-Host ("VM_SWITCH_PUB_NAME: " + $vmPubSwitch)
    $validationFlag = $False
}

$ret = Get-VMSwitch | Where-Object {$_.Name -eq $vmAppSwitch}
if ($ret -eq $null) {
    Write-Host "VM_SWITCH_APP_NAME does not exist."
    Write-Host ("VM_SWITCH_APP_NAME: " + $vmAppSwitch)
    $validationFlag = $False
}
#>

# Need to check IP address
# Need to check subnet mask

if ($validationFlag -ne $True) {
    Write-Host ""
    Write-Host "Validation failed."
    exit 0
}

Write-Host "Validation checks are passed."

##### Import Router VM template
Write-Host "Importing Router VM template..."

$ret = Get-VM | Where-Object {$_.Name -eq $vmName}
if ($ret -eq $null) {
    Import-VM -Path $vmcxPath -Confirm:$False
    Write-Host "Router VM has been imported successfully."
} else {
    while (1) {
	    Write-Host ""
	    $confirm = Read-Host "RouterVM_template already exists. Do you proceed to setup this VM? (yes/no)"

	    if ($confirm -eq "yes") {
		    break
	    } elseif ($confirm -eq "no") {
		    Write-Host "Setup is cancelled."
		    exit 0
	    } else {
            Write-Host "Please input yes or no."
        }
    }
}

##### Start Router VM
Write-Host "Starting Router VM..."

Start-VM -Name $vmName
Write-Host "Router VM has been started."

##### Initialize KVP
for ($i = 0; $i -lt $keyList.Length; $i++) {
    $ret = delete_kvp $keyList[$i] $vmName
}

##### Check if VM is ready for receiving KVP values
Write-Host "Waiting for Router VM to become ready..."

while (1) {
    $key = "init"
    $ret = read_kvp $key $vmName
    if ($ret -ne "SYN") {
        Start-sleep -s 3
        continue
    }
    break
}

Write-Host "Router VM has become ready."

##### Copy ssh key to VM
Write-Host "Creating SSH key to access Router VM via SSH..."

$key = "key"
$ret = read_kvp $key $vmName
if ($ret -ne "OK") {
    $ret = Test-Path C:\Users\Administrator\.ssh\id_rsa.pub
    if ($ret -ne $true) {
        Write-Host "Please press return key in all questions."
        ssh-keygen
        Write-Host "SSH key has been created."
    } else {
        Write-Host "SSH key already exists. No need to create SSH key."
    }

    Copy-Item C:\Users\Administrator\.ssh\id_rsa.pub .
    Copy-Item C:\Users\Administrator\.ssh\id_rsa .

    Write-Host "Copying SSH key to Router VM..."
    Copy-VMFile -Name "$vmName" -SourcePath ".\id_rsa.pub" -DestinationPath "/root/.ssh/" -FileSource Host -Force

    $key = "key"
    $value = "SEND"
    $ret = create_kvp $key $value $vmName

    Write-Host "SSH key has been sent to Router VM."

    ##### Check if key setup is completed
    Write-Host "Waiting for Router VM to receive SSH key..."

    while (1) {
        $key = "key"
        $ret = read_kvp $key $vmName
        if ($ret -eq "OK") {
            break
        }
    }
}

Write-Host "Router VM has received SSH key."

##### Send KVP for IP address
Write-Host "Waiting for Router VM to set IP address..."

$key = "ip"
$ret = read_kvp $key $vmName
if ($ret -ne "OK") {
    $key = "ipPub"
    $value = $ipPub + "/" + $ipPubSubnet
    $ret = create_kvp $key $value $vmName
    $key = "netPub"
    $value = $netPub + "/" + $ipPubSubnet
    $ret = create_kvp $key $value $vmName
    $key = "ipApp"
    $value = $ipApp + "/" + $ipAppSubnet
    $ret = create_kvp $key $value $vmName
    $key = "netApp"
    $value = $netApp + "/" + $ipAppSubnet
    $ret = create_kvp $key $value $vmName
    $key = "ipDns"
    $value = $ipDns
    $ret = create_kvp $key $value $vmName
    $key = "ipGateway"
    $value = $ipGateway
    $ret = create_kvp $key $value $vmName

    $key = "ip"
    $value = "SEND"
    $ret = create_kvp $key $value $vmName

    while (1) {
        $key = "ip"
        $ret = read_kvp $key $vmName
        if ($ret -eq "OK") {
            break
        }
    }

    $key = "ip"
    $value = "ACK"
    $ret = modify_kvp $key $value $vmName
}

Write-Host "Router VM has set IP address."

##### Verify MAC address

$key = "MAC"
$ret = read_kvp $key $vmName
if ($ret -ne "OK") {
    while (1) {
        $key = "pubMAC"
        $pubMAC = read_kvp $key $vmName
        if ($pubMAC -ne $null) {
            break
        }
    }

    $key = "MAC"
    $value = "pubMAC"
    $ret = create_kvp $key $value $vmName

    while (1) {
        $key = "appMAC"
        $appMAC = read_kvp $key $vmName
        if ($appMAC -ne $null) {
            break
        }
    }

    $key = "MAC"
    $value = "appMAC"
    $ret = modify_kvp $key $value $vmName

    while (1) {
        $key = "MAC"
        $ret = read_kvp $key $vmName
        if ($ret -eq "OK") {
            break
        }
    }

    $vmNIC0MAC = (Get-VMNetworkAdapter -VMName $vmName | Where-Object {$_.Name -eq "NIC0"}).MacAddress
    $vmNIC1MAC = (Get-VMNetworkAdapter -VMName $vmName | Where-Object {$_.Name -eq "NIC1"}).MacAddress
    $pubMAC = $pubMAC.Replace(":", "")
    $appMAC = $appMAC.Replace(":", "")

    if ($pubMAC -eq $vmNIC0MAC) {
        Rename-VMNetworkAdapter -VMName $vmName -Name "NIC0" -NewName $vmPubNICTemplate
        Rename-VMNetworkAdapter -VMName $vmName -Name "NIC1" -NewName $vmAppNICTemplate
    } else {
        Rename-VMNetworkAdapter -VMName $vmName -Name "NIC1" -NewName $vmPubNICTemplate
        Rename-VMNetworkAdapter -VMName $vmName -Name "NIC0" -NewName $vmAppNICTemplate
    }

    $key = "MAC"
    $value = "ACK"
    $ret = modify_kvp $key $value $vmName
}

##### Set OSPF in router VM
while (1) {
    $key = "OSPF"
    $ret = read_kvp $key $vmName
    if ($ret -eq "OK") {
        break
    }
}

Write-Host "OSPF is enabled in Router VM."

##### Connect via SSH
ssh-keyscan $ipPub | Out-File C:\Users\Administrator\.ssh\known_hosts -Append -Encoding ASCII
$line = "root@" + $ipPub
#ssh -q -i ".\id_rsa" -o StrictHostKeyChecking=no $line $ipconfig
ssh -q -o StrictHostKeyChecking=no $line "ip a"


##### Attach virtual switched to VMs
Write-Host "Attaching virtual switches to RouterVM..."

Connect-VMNetworkAdapter -VMName $vmName -Name $vmPubNICTemplate -SwitchName $vmPubSwitch
Connect-VMNetworkAdapter -VMName $vmName -Name $vmAppNICTemplate -SwitchName $vmAppSwitch

Write-Host "Virtual switches are attached to RouterVM."

##### Wait before initialization of KVP
for ($i = 0; $i -lt 3; $i++) {
    Start-sleep -s 1
}

##### initialize KVP
for ($i = 0; $i -lt $keyList.Length; $i++) {
    $ret = delete_kvp $keyList[$i] $vmName
}