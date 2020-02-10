rem ***************************************
rem *               genw.bat              *
rem ***************************************
rem ***************************************
rem *               genw.bat              *
rem *              2019/11/13             *
rem ***************************************

cd "..\scripts\failover\replica_script"
call .\cluster_config.bat
cd "..\..\monitor.s\monitor_nic"
armload NICRECOVER /U Administrator /W Powershell.exe .\recover.ps1
armkill NICRECOVER

set ret=%ERRORLEVEL%
echo %ret%