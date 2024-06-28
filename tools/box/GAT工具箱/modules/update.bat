@echo off
copy "\\glbfs14\sw_releases\Wireless_Global_Tools\Tool_Release\Debugging Tool\GAT\update\update.jar"
java -jar update.jar %1
@cd /d %~dp0
if "%1"=="" goto end
set /p="Do you want to restart GAT tool?[Y,N]"/<nul
set /p input=
if not %input%==Y if not %input%==y goto end
call ../GAT.bat
:end
::exit