$VmMgmt = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_VirtualSystemManagementService  
$vm = Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter {ElementName='RouterVM_template'}  
$kvpDataItem = ([WMIClass][String]::Format("\\{0}\{1}:{2}", `   
    $VmMgmt.ClassPath.Server, `   
    $VmMgmt.ClassPath.NamespacePath, `   
    "Msvm_KvpExchangeDataItem")).CreateInstance()  
  
$kvpDataItem.Name = "init"   
$kvpDataItem.Data = [String]::Empty   
$kvpDataItem.Source = 0  
  
$VmMgmt.RemoveKvpItems($Vm,   
$kvpDataItem.PSBase.GetText(1))