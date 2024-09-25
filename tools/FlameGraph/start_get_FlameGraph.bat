@echo off
chcp 936

REM 可传入变量p1 = pid 需要检测的进程pid ； p2 = time 需要检测的秒数

REM 设置NDK路径 (更新为你的NDK安装路径) 必要配置项 NDK:https://developer.android.google.cn/ndk/downloads
set FLAG=0
set NDK_PATH=D:\android-ndk-r26d-windows\android-ndk-r26d

REM 启用延迟变量扩展
setlocal EnableDelayedExpansion

REM 设置获取PID的Python脚本路径
set SCRIPT_PATH=D:\workplace\tools\basic_api_android\get_pid.py

REM 先标记一下
if "%~1"=="" (
    set FLAG=1
) else (
    set FLAG=0
)

REM 调用Python脚本并获取PID
for /f "tokens=*" %%i in ('python "%SCRIPT_PATH%"') do (
    set PID=%%i
)
echo The PID of the current focused app is !PID!

REM 检查是否传入PID作为第一个参数
if "!FLAG!"=="0" (
    set PID=%~1
    echo Using provided PID: !PID!
)

REM 检查是否传入持续时间作为第二个参数
if "%~2"=="" (
    set DURATION=5
) else (
    set DURATION=%~2
)

echo.
echo ================================================
echo ====== Recording performance data on the =======
echo ====== Android device for %DURATION% seconds... =======
echo ================================================
echo.

REM 使用simpleperf记录设备上的性能数据
adb shell simpleperf record -p %PID% --duration %DURATION% -g --call-graph fp -o /sdcard/perf.data

if %errorlevel% neq 0 (
    echo Failed to record performance data on the device.
    pause
    exit /b %errorlevel%
)

echo.
echo ================================================
echo ====== Pulling perf.data from Android device =====
echo ================================================
echo.

REM 从设备上拉取perf.data文件
adb pull /sdcard/perf.data

if %errorlevel% neq 0 (
    echo Failed to pull perf.data from the device.
    pause
    exit /b %errorlevel%
)

echo.
echo ================================================
echo ====== Generating out.perf using ================
echo ====== report_sample.py... =====================
echo ================================================
echo.

REM 使用report_sample.py生成中间的out1.perf文件
python %NDK_PATH%\simpleperf\report_sample.py > out.perf

if %errorlevel% neq 0 (
    echo Failed to generate out.perf
    pause
    exit /b %errorlevel%
)

echo.
echo ================================================
echo ====== Collapsing stack data using =============
echo ====== stackcollapse-perf.pl... ===============
echo ================================================
echo.

REM 使用stackcollapse-perf.pl将perf数据折叠为folded格式
perl stackcollapse-perf.pl out.perf > out.folded

if %errorlevel% neq 0 (
    echo Failed to collapse stack data.
    pause
    exit /b %errorlevel%
)

echo.
echo ================================================
echo ====== Generating Flame Graph out.svg ==============
echo ================================================
echo.

REM 使用flamegraph.pl生成火焰图
perl flamegraph.pl out.folded > out.svg

if %errorlevel% neq 0 (
    echo Failed to generate the Flame Graph.
    pause
    exit /b %errorlevel%
)

if %errorlevel% neq 0 (
    echo Failed to move the file to Desktop.
    pause
    exit /b %errorlevel%
)

echo.
echo ================================================
echo ====== Moving the out.svg to Desktop  ====
echo ================================================
echo.

move out.svg %USERPROFILE%\Desktop\out.svg

pause
endlocal
