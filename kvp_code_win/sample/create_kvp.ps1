$vmName = "RouterVM_template"
$key = "init"
$value = "ok"

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