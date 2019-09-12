#$vmName = "Cent7.4-router2"
$vmName = "RouterVM_template"
$filter = "ElementName = '$vmName'"
$key = "key"

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
    Write-Host "error"
}

$output = "ret:" + $ret + "."
Write-Host $output