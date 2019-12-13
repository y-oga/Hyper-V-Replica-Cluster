rem ***************************************
rem *               genw.bat              *
rem ***************************************
rem ***************************************
rem *               genw.bat              *
rem *              2019/11/13             *
rem ***************************************

cd "..\scripts\failover\replica_script"
call .\cluster_config.bat
cd "..\..\monitor.s\monitor_replica"
armload REPRECOVER /U Administrator /W Powershell.exe .\recover.ps1
armkill REPRECOVER

set ret=%ERRORLEVEL%
echo %ret%
