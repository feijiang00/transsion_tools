@cd /d %~dp0
@cd modules
@call update.bat
@cd ..
@start modules\monitor\GAT.exe
@exit