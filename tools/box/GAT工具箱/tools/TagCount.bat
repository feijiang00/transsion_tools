@cd /d %~dp0
@set java_exe=java
@java -version 2>nul
@if ERRORLEVEL 1 goto noJavaInstalled

@call %java_exe% -jar ..\utility\TagCount.jar %1
@Pause
@exit

:noJavaInstalled
echo.
echo ERROR: No suitable Java found. In order to properly use the TagCount
echo Tools, you need a suitable version of Java JDK installed on your system.
echo We recommend that you install the JDK version of JavaSE, available here:
echo   http://www.oracle.com/technetwork/java/javase/downloads
echo.
@Pause
@exit
