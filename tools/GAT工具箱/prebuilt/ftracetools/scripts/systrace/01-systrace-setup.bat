@echo off
adb shell "setprop debug.egl.traceGpuCompletion 1"
adb shell "setprop debug.atrace.tags.enableflags 0x003fe"
rem adb shell "setprop debug.atrace.tags.enableflags 0x3fe"
adb shell "stop;start"
echo "please press catch-systrace.bat to collect trace"
pause
