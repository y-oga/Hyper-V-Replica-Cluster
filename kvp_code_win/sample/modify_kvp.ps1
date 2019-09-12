$VmMgmt = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService  
$vm = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter {ElementName='Cent7.4-router2'}  
$kvpDataItem = ([WMIClass][String]::Format("\\{0}\{1}:{2}", `   
    $VmMgmt.ClassPath.Server, `   
    $VmMgmt.ClassPath.NamespacePath, `   
    "Msvm_KvpExchangeDataItem")).CreateInstance()  
  
$kvpDataItem.Name = "IPaddress2"   
$kvpDataItem.Data = "192.168.0.100"   
$kvpDataItem.Source = 0  
  
$VmMgmt.ModifyKvpItems($Vm, $kvpDataItem.PSBase.GetText(1))