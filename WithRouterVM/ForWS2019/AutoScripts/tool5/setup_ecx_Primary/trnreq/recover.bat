rem Nov 5 2019

cd "..\..\scripts\failover\replica_script"
call .\cluster_config.bat
cd "..\..\..\work\trnreq"
armload REPREXEC /U Administrator /W Powershell.exe .\recover.ps1
armkill REPREXEC
