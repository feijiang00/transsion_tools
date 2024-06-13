@echo off
chcp 936

set filename=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%
set "filename=%filename: =0%"

set capture_time=5
if not "%1"=="" (
    set capture_time=%1
)

echo "start capture trace, time %capture_time%s"

if not "%2"=="" (
    adb -s "%2" shell atrace -t %capture_time% -b 102400 gfx input sched disk view webview wm am sm video hal res dalvik bionic power pm ss sched freq idle memreclaim binder_driver binder_lock camera aidl irq > C:\Users\tingjiang.wang\Desktop\%filename%
) else (
    adb shell atrace -t %capture_time% -b 102400 gfx input sched disk view webview wm am sm video hal res dalvik bionic power pm ss sched freq idle memreclaim binder_driver binder_lock camera aidl irq > C:\Users\tingjiang.wang\Desktop\%filename%
)

echo "capture done, start unzip"

"D:\transsion\android_test_tool\perfconv\perfconv.exe" convert "C:\Users\tingjiang.wang\Desktop\%filename%"