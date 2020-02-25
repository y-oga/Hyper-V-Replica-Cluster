rem ***************************************
rem *               genw.bat              *
rem ***************************************
rem ***************************************
rem *               genw.bat              *
rem *              2020/02/25             *
rem ***************************************

cd "..\scripts\INPUT_FAILOVER_NAME\INPUT_RESOURCE_NAME"
call .\cluster_config.bat
cd "..\..\monitor.s\INPUT_MONITOR_NAME"
armload INPUT_REPRECOVER /U Administrator /W Powershell.exe .\recover.ps1
armgetcd INPUT_RETURNGENW
set ret=%ERRORLEVEL%
if %ret% equ 2 exit 1
