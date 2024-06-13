set filename=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%
set "filename=%filename: =0%"
adb shell perfetto -o /data/misc/perfetto-traces/%filename%.perfetto-trace -t 5s gfx input sched disk view webview wm am sm video hal res dalvik bionic power pm ss sched freq idle memreclaim binder_driver binder_lock camera aidl irq
adb pull /data/misc/perfetto-traces/%filename%.perfetto-trace C:/Users/tingjiang.wang/Desktop
