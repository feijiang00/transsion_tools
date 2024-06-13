% Writed by yanghui.li <yanghui.li@mediatek.com> version 00.21%
% 2013/5/25 Update check java install process for windows7, auto copy java.exe to system32%
% 2013/6/15 Update the install directory%
% 2013/7/20 Update the AutoUpdate feature%

echo QAAT Check Start.

@echo off
if not exist "%windir%\system32\java.exe" (
    if not exist "%windir%\SysWOW64\java.exe" (
        echo No JDK is found, please install JDK
        pause
        exit
    )
    copy "%windir%\SysWOW64\java.exe" "%windir%\system32\java.exe"
)

set version=0024
if exist "c:\QAAT\AutoUpdate.jar" (
    java -jar c:\QAAT\AutoUpdate.jar -v %version%
)

if exist "c:\QAAT\aee_extract.exe" (
    if exist "%windir%\system32\aee_extract.exe" (
       del %windir%\system32\aee_extract.exe
    )
    if exist "%windir%\syswow64" (
       if exist "%windir%\syswow64\aee_extract.exe" (
           del %windir%\syswow64\aee_extract.exe
       )
    )
   echo copy aee_extract to system32 and syswow64
   copy "c:\QAAT\aee_extract.exe" "%windir%\system32\aee_extract.exe"
   if exist "%windir%\syswow64" (
        copy "c:\QAAT\aee_extract.exe" "%windir%\syswow64\aee_extract.exe"
   )
   del c:\QAAT\aee_extract.exe
)

set qaat_path=c:\QAAT\QAAT-ProGuard.jar

if not exist "c:\QAAT\QAAT-ProGuard.jar" (
   set qaat_path=QAAT-ProGuard.jar
)

@echo on
java -jar %qaat_path% -d %1

@echo off
if exist "analysis_result.txt" (
    start analysis_result.txt
)

pause