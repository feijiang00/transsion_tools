@echo off

rem 设置默认值
set total_swipes=18
set interval_seconds=10

rem 检查是否传入了自定义值
if not "%~1"=="" set total_swipes=%~1
if not "%~2"=="" set interval_seconds=%~2

echo Starting swipe operation...

rem 循环执行滑动操作
for /l %%i in (1,1,%total_swipes%) do (
    echo Swipe %%i / %total_swipes%
    adb shell input swipe 500 1500 500 500 500
    rem 暂停指定的秒数
    timeout /t %interval_seconds% >nul
)

echo Swipe operation completed.
