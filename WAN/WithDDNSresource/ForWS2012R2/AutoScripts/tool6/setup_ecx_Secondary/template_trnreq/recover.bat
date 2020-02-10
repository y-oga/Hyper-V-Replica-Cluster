rem Feb 10 2020

cd "..\..\scripts\INPUT_FAILOVER_NAME\INPUT_RESOURCE_NAME"
call .\cluster_config.bat
cd "..\..\..\work\trnreq"
armload INPUT_REPREXEC /U Administrator /W Powershell.exe .\recover.ps1
armkill INPUT_REPREXEC
