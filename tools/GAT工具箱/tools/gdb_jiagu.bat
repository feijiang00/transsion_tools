@echo off
@cd /d %~dp0
@cd ..\prebuilt\android-sdk\bin
cd ..\..\python\bin
set PYTHONHOME=..\..\python
set PYTHONPATH=..\..\python\lib\python2.7
set path=%path%;%PYTHONPATH%;
echo %path%
@REM pause
gdb.exe --iex \"set osabi GNU/Linux\" --cd=..\..\..\plugin-scripts\coretracer --eval-command="\"source jiagu.py\""
exit
