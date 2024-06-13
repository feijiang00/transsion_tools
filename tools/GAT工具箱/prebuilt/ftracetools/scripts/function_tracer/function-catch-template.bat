@echo off
adb shell "echo 16384 > /sys/kernel/debug/tracing/buffer_size_kb"
adb shell "echo function_graph > /sys/kernel/debug/tracing/current_tracer"
rem just in case tracing_enabled is disabled by user or other debugging tool
adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_enabled" >nul 2>&1
adb shell "echo 0 > /sys/kernel/debug/tracing/tracing_on"
rem erase previous recorded trace
adb shell "echo > /sys/kernel/debug/tracing/trace"
echo press any key to start capturing...
pause

adb shell "echo <function> > /sys/kernel/debug/tracing/set_graph_function"

adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_on"

echo "Start recordng ftrace data"
echo "Press any key to stop..."
pause

adb shell "echo 0 > /sys/kernel/debug/tracing/tracing_on"
echo "Recording stopped..."
adb pull /sys/kernel/debug/tracing/trace SYS_FTRACE
adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_on"
pause
