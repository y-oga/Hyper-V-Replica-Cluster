rem ***************************************
rem *              stop.bat               *
rem *                                     *
rem * title   : stop script file sample   *
rem * date    : 2020/02/25                *
rem * version : 9.0.3-1                   *
rem ***************************************


cd "%CLP_SCRIPT_PATH%"
call cluster_config.bat


rem ***************************************
rem Check startup attributes
rem ***************************************
IF "%CLP_EVENT%" == "START" GOTO NORMAL
IF "%CLP_EVENT%" == "FAILOVER" GOTO FAILOVER

rem Cluster Server is not started
GOTO no_arm





rem ***************************************
rem Process for normal quitting program
rem ***************************************
:NORMAL

rem Check Disk
IF "%CLP_DISK%" == "FAILURE" GOTO ERROR_DISK


rem *************
rem Routine procedure
rem *************

armload INPUT_REPSTOP /U Administrator /W powershell.exe .\stop.ps1
armgetcd INPUT_RETURNSTOP
set ret=%ERRORLEVEL%
if %ret% equ 2 exit 1

rem Priority check
IF "%CLP_SERVER%" == "OTHER" GOTO ON_OTHER1

rem *************
rem Highest Priority Process
rem (Example) ARMBCAST /MSG "Quitting on the highest priority server" /A
rem *************
GOTO EXIT


:ON_OTHER1
rem *************
rem Other Process
rem (Example) ARMBCAST /MSG "Quitting on the other server(s) except the highest priority server" /A
rem *************
GOTO EXIT





rem ***************************************
rem Process for failover
rem ***************************************
:FAILOVER

rem Check Disk
IF "%CLP_DISK%" == "FAILURE" GOTO ERROR_DISK


rem *************
rem Starting applications/services and recovering process after failover
rem *************

armload INPUT_REPSTOP /U Administrator /W powershell.exe .\stop.ps1
armgetcd INPUT_RETURNSTOP
set ret=%ERRORLEVEL%
if %ret% equ 2 exit 1

rem Priority check
IF "%CLP_SERVER%" == "OTHER" GOTO ON_OTHER2

rem *************
rem Highest Priority Process
rem (Example) ARMBCAST /MSG "Finishing on the highest priority server (after failover)" /A
rem *************
GOTO EXIT

:ON_OTHER2
rem *************
rem Other Process
rem (Example) ARMBCAST /MSG "Finishing on the other server(s) except the highest priority server(after failover)" /A
rem *************
GOTO EXIT




rem ***************************************
rem Irregular process
rem ***************************************

rem Process for disk errors
:ERROR_DISK
ARMBCAST /MSG "Failed to connect the switched disk partition" /A
GOTO EXIT


rem Cluster Server is not started
:no_arm
ARMBCAST /MSG "Cluster Server is offline" /A


:EXIT
