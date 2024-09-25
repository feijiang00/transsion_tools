% Writed by yanghui.li <yanghui.li@mediatek.com> version 00.21%
% 2013/5/25 Update check java install process for windows7, auto copy java.exe to system32%
% 2013/5/25 Copy aee_extract.exe to system32 and syswow64 in windows7-x64%
% 2013/6/15 Update install dir to C::QAAT%

echo QAAT Setup start.

@echo off
if not exist "%windir%\system32\java.exe" (
    if not exist "%windir%\SysWOW64\java.exe" (
        echo No JDK is found, please install JDK
        pause
        exit
    )
    copy "%windir%\SysWOW64\java.exe" "%windir%\system32\java.exe"
)

if exist "%windir%\system32\aee_extract.exe" (
    del %windir%\system32\aee_extract.exe
)
if exist "%windir%\syswow64" (
    if exist "%windir%\syswow64\aee_extract.exe" (
        del %windir%\syswow64\aee_extract.exe
    )
)
echo copy aee_extract to system32 and syswow64(x64)
copy "aee_extract.exe" "%windir%\system32\aee_extract.exe"
if exist "%windir%\syswow64" (
    copy "aee_extract.exe" "%windir%\syswow64\aee_extract.exe"
)

if not exist "c:\QAAT\" (
    md "c:\QAAT\"
)

if exist "c:\QAAT\QAAT-ProGuard.jar" (
    del c:\QAAT\QAAT-ProGuard.jar
)
echo copy QAAT-ProGuard.jar to c:\QAAT\
copy QAAT-ProGuard.jar c:\QAAT\

if exist "c:\QAAT\Run-QAAT-ProGuard.bat" (
    del c:\QAAT\Run-QAAT-ProGuard.bat
)
echo copy Run-QAAT-ProGuard.bat to c:\QAAT\
copy Run-QAAT-ProGuard.bat c:\QAAT\

if exist "c:\QAAT\AutoUpdate.jar" (
    del c:\QAAT\AutoUpdate.jar
)
echo copy AutoUpdate.jar to c:\QAAT\
copy AutoUpdate.jar c:\QAAT\

@echo off 
echo Windows Registry Editor Version 5.00>>temp.reg
echo.>>temp.reg 
echo [HKEY_CLASSES_ROOT\Directory\shell\bat]>>temp.reg
echo @="QAAT-Check">>temp.reg
echo.>>temp.reg
echo [HKEY_CLASSES_ROOT\Directory\shell\bat\command]>>temp.reg
echo @="c:\\QAAT\\Run-QAAT-ProGuard.bat \"%%l\"" >> temp.reg
echo.>>temp.reg 
echo [HKEY_CLASSES_ROOT\*\shell\bat]>>temp.reg
echo @="QAAT-Check">>temp.reg
echo.>>temp.reg
echo [HKEY_CLASSES_ROOT\*\shell\bat\command]>>temp.reg
echo @="c:\\QAAT\\Run-QAAT-ProGuard.bat \"%%l\"" >> temp.reg

@echo on
echo register QAAT

@echo off
c:\windows\regedit -s temp.reg
del  temp.reg

echo QAAT Setup success.

pause