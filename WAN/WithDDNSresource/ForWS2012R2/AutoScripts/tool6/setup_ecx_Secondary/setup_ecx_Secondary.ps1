# Feb 19 2020

$product = $env:ECX_OR_CLP
$vmNum = $env:APP_VM_NUM
$tmp1 = $env:APP_VM_NAME1
$tmp2 = $env:APP_VM_NAME2
$tmp3 = $env:APP_VM_NAME3
$tmp4 = $env:APP_VM_NAME4
$tmp5 = $env:APP_VM_NAME5
$tmp6 = $env:APP_VM_NAME6
$targetVM = @($tmp1, $tmp2, $tmp3, $tmp4, $tmp5, $tmp6)
$failover = @()
for ($i = 0; $i -lt $vmNum; $i++) {
    $failover += "failover_" + $targetVM[$i];
}

for ($i = 0; $i -lt $vmNum; $i++) {
    # Edit trnreq script
    $output_path = ".\trnreq"
    Copy-Item ".\template_trnreq\*" $output_path -Recurse -Force
    $file_path = $output_path + "\recover.bat"
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_FAILOVER_NAME",$failover[$i]
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $tmp = "replica_" + $targetVM[$i]
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_RESOURCE_NAME",$tmp
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $tmp = "monitor_" + $targetVM[$i]
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_MONITOR_NAME",$tmp
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $tmp = "REPREXEC" + ($i + 1)
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_REPREXEC",$tmp
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $tmp = "recover_" + $targetVM[$i] + ".bat"
    Rename-item -Path $file_path -NewName $tmp
}

clpcl -r --web --alert
armem /M reboot

$path = "C:\Program Files\EXPRESSCLUSTER\work"
if ($product -eq "CLP") {
    $path = "C:\Program Files\CLUSTERPRO\work"
}

Copy-Item ".\trnreq" -Destination $path -Recurse -Force

