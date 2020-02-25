# Feb 25 2020

$lcnsPath = $env:LCNS_PATH
$product = $env:ECX_OR_CLP
$pHostname = $env:PRIMARY_HOSTNAME
$pIp = $env:PRIMARY_IP_ADDRESS
$sHostname = $env:SECONDARY_HOSTNAME
$sIp = $env:SECONDARY_IP_ADDRESS
$domain = $env:DOMAIN
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
$adminPass = $env:ADMIN_PASS

$pHostname = $pHostname.ToLower()
$sHostname = $sHostname.ToLower()

$objNum = 12 + ($vmNum - 1) * 3

for ($i = 0; $i -lt $vmNum; $i++) {
    # Edit Replica script
    $output_path = ".\scripts\" + $failover[$i] + "\replica_" + $targetVM[$i]
    New-Item $output_path -ItemType Directory
    Copy-Item ".\template_scripts\failover\replica_script\*" $output_path -Recurse -Force
    $file_path = $output_path + "\cluster_config.bat"
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_PRIMARY_HOSTNAME",$pHostname
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_PRIMARY_HOST_IP_ADDRESS",$pIp
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_SECONDARY_HOSTNAME",$sHostname
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_SECONDARY_HOST_IP_ADDRESS",$sIp
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_TARGET_VM_NAME",$targetVM[$i]
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_FAILOVER_NAME",$failover[$i]
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_DOMAIN_NAME",$domain
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $monNumber = $i + 1
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_MONITOR_NUMBER",$monNumber
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte

    # Edit start.bat
    $file_path = $output_path + "\start.bat"
    $insertData = "REPNORMAL" + ($i + 1)
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_REPNORMAL",$insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $insertData = "REPFAILOVER" + ($i + 1)
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_REPFAILOVER",$insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $insertData = "RETURNSTART" + ($i + 1)
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_RETURNSTART",$insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte

    # Edit stop.bat
    $file_path = $output_path + "\stop.bat"
    $insertData = "REPSTOP" + ($i + 1)
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_REPSTOP",$insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $insertData = "RETURNSTOP" + ($i + 1)
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_RETURNSTOP",$insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte

    # Edit Monitor script
    $output_path = ".\scripts\monitor.s\monitor_" + $targetVM[$i]
    New-Item $output_path -ItemType Directory
    Copy-Item ".\template_scripts\monitor.s\monitor_replica\*" $output_path -Recurse -Force
    $file_path = $output_path + "\genw.bat"
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_FAILOVER_NAME",$failover[$i]
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $tmp = "replica_" + $targetVM[$i]
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_RESOURCE_NAME",$tmp
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $tmp = "monitor_" + $targetVM[$i]
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_MONITOR_NAME",$tmp
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $tmp = "REPRECOVER" + ($i + 1)
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_REPRECOVER",$tmp
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
    $insertData = "RETURNGENW" + ($i + 1)
    $file_contents = $(Get-Content $file_path) -creplace "INPUT_RETURNGENW",$insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte

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

# Add failover group
$file_path = ".\clp.conf"
for ($i = 0; $i -lt $vmNum; $i++) {
    $insertData = "<group name=`"" + $failover[$i] + "`">
                    <comment/>
                    <resource name=`"script@replica_" + $targetVM[$i] + "`"/>
                   </group>"
    $replaceTarget = "<GRP" + ($i + 1) + ">"

    $file_contents = $(Get-Content $file_path) -creplace $replaceTarget, $insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
}
for ($i = [int]$vmNum; $i -lt 6; $i++) {
    $insertData = ""
    $replaceTarget = "<GRP" + ($i + 1) + ">"

    $file_contents = $(Get-Content $file_path) -creplace $replaceTarget, $insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
}

# Add resource
for ($i = 0; $i -lt $vmNum; $i++) {
    $insertData = "<script name=`"replica_" + $targetVM[$i] + "`">
                        <comment/>
                        <parameters>
                            <recoveruse>1</recoveruse>
                        </parameters>
                        <act>
                            <retry>3</retry>
                        </act>
                    </script>"
    $replaceTarget = "<RSC" + ($i + 1) + ">"

    $file_contents = $(Get-Content $file_path) -creplace $replaceTarget, $insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
}
for ($i = [int]$vmNum; $i -lt 6; $i++) {
    $insertData = ""
    $replaceTarget = "<RSC" + ($i + 1) + ">"

    $file_contents = $(Get-Content $file_path) -creplace $replaceTarget, $insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
}

# Add genw
for ($i = 0; $i -lt $vmNum; $i++) {
    $insertData = "<genw name=`"monitor_" + $targetVM[$i] + "`">
                    <comment/>
                    <polling>
                      <interval>5</interval>
                      <timing>1</timing>
                      <timeout>120</timeout>
                    </polling>
                    <target>replica_" + $targetVM[$i] + "</target>
                    <relation>
                      <name>replica_" + $targetVM[$i] + "</name>
                      <type>rsc</type>
                    </relation>
                    <emergency>
                      <prefailover>
                        <migration>0</migration>
                      </prefailover>
                      <threshold>
                        <restart>1</restart>
                        <fo2>1</fo2>
                      </threshold>
                    </emergency>
                    <parameters>
                      <waitstop>1</waitstop>
                    </parameters>
                  </genw>"
    $replaceTarget = "<GENW" + ($i + 1) + ">"

    $file_contents = $(Get-Content $file_path) -creplace $replaceTarget, $insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
}
for ($i = [int]$vmNum; $i -lt 6; $i++) {
    $insertData = ""
    $replaceTarget = "<GENW" + ($i + 1) + ">"

    $file_contents = $(Get-Content $file_path) -creplace $replaceTarget, $insertData
    $file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
}

# Add system parameters
$file_contents = $(Get-Content $file_path) -creplace "INPUT_PASS",$adminPass
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
$file_contents = $(Get-Content $file_path) -creplace "INPUT_HOST1",$pHostname.ToLower()
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
$file_contents = $(Get-Content $file_path) -creplace "INPUT_IP1",$pIp
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
$file_contents = $(Get-Content $file_path) -creplace "INPUT_HOST2",$sHostname.ToLower()
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
$file_contents = $(Get-Content $file_path) -creplace "INPUT_IP2",$sIp
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte
$file_contents = $(Get-Content $file_path) -creplace "INPUT_OBJECT_NUMBER",$objNum
$file_contents | Out-String | % { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path $file_path -Encoding Byte

$line = "root@" + $prIp

clplcnsc -i $lcnsPath
clpcl -t -a

clpcfctrl --push -w -x .

clpcl -r --web --alert

$path = "C:\Program Files\EXPRESSCLUSTER\work"
if ($product -eq "CLP") {
    $path = "C:\Program Files\CLUSTERPRO\work"
}
Copy-Item ".\trnreq" -Destination $path -Recurse -Force

clpcl -s -a

armem /M reboot

Write-Host "Starting a cluster."