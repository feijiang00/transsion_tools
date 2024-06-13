REM 每隔一段时间输出apk的内存，完整参数执行例子：
REM .\dumpsys_apk_meminfo.bat com.google.android.youtube x6850 5 output.txt（测试包名 文件名前缀  时间间隔 输出的路径)(一般使用前两个参数)
REM 如果有时候apk 包名的内存信息无法dump下来，换成pid，或者系统中开启了两个这个apk

@echo off
chcp 65001
REM 设置默认文件路径为当前目录下的meminfo.txt
set "filepath=%~4"
if "%filepath%"=="" set "filepath=meminfo.txt"

REM 设置默认时间停顿间隔为10秒
set "interval=%~3"
if "%interval%"=="" set "interval=10"

REM 获取文件名前缀，如果没有传入，默认使用"meminfo"，也就是输出文件的前缀
set "apkname=%~2"
if "%apkname%"=="" set "apkname=jiangjiang"

REM 获取要测试的apk包名，必须传入，没有默认值
set "apk=%~1"
if "%apk%"=="" (
    echo 未输入需要测试的apk包名
    exit /b 1
) else (
    set "apk=%apk%"
)

REM 构造输出文件名
set "outputfile=%apkname%_meminfo.txt"

REM 开始循环
:start
adb shell dumpsys meminfo %apk% >> %outputfile%
timeout /t %interval% >nul
REM 跳转回循环起始点
goto start