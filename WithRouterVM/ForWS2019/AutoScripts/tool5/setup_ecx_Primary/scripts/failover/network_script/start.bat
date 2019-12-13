rem ***************************************
rem *              start.bat              *
rem *                                     *
rem * title   : start script file sample  *
rem * date    : 2019/10/30                *
rem * version : 9.0.3-1                   *
rem ***************************************

cd "..\scripts\failover\replica_script"
call .\cluster_config.bat
cd "%CLP_SCRIPT_PATH%"

rem ***************************************
rem Check startup attributes
rem ***************************************
IF "%CLP_EVENT%" == "START" GOTO NORMAL
IF "%CLP_EVENT%" == "FAILOVER" GOTO FAILOVER
IF "%CLP_EVENT%" == "RECOVER" GOTO RECOVER

rem Cluster Server is not started
GOTO no_arm





rem ***************************************
rem Normal Startup process
rem ***************************************
:NORMAL


rem Check Disk
IF "%CLP_DISK%" == "FAILURE" GOTO ERROR_DISK


rem *************
rem Routine procedure
rem *************

armload NICUP /U Administrator /W powershell.exe .\start.ps1

rem Priority check
IF "%CLP_SERVER%" == "OTHER" GOTO ON_OTHER1

rem *************
rem Highest Priority Process
rem (Example) ARMBCAST /MSG "Running on the highest priority server" /A
rem *************
GOTO EXIT

:ON_OTHER1
rem *************
rem Other Process
rem (Example) ARMBCAST /MSG "Running on the other server(s) except the highest priority server" /A
rem *************
GOTO EXIT





rem ***************************************
rem Recovery process
rem ***************************************
:RECOVER

rem *************
rem Recovery process after return to the cluster
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

armload NICUP /U Administrator /W powershell.exe .\start.ps1

rem Priority check
IF "%CLP_SERVER%" == "OTHER" GOTO ON_OTHER2

rem *************
rem Highest Priority Process
rem (Example) ARMBCAST /MSG "Running on the highest priority server(after failover)" /A
rem *************
GOTO EXIT

:ON_OTHER2
rem *************
rem Other Process
rem (Example) ARMBCAST /MSG "Running on the other server(s) except the highest priority server(after failover)" /A
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
