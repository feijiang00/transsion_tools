@echo off
adb shell "echo 16384 > /sys/kernel/debug/tracing/buffer_size_kb"

adb shell "echo nop > /sys/kernel/debug/tracing/current_tracer"
adb shell "echo 'workqueue ext4_sync_file_enter ext4_sync_file_exit block_rq_issue block_rq_complete cpu_idle cpu_frequency sched_switch sched_wakeup sched_wakeup_new sched_migrate_task irq' > /sys/kernel/debug/tracing/set_event"
rem just in case tracing_enabled is disabled by user or other debugging tool
adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_enabled"
adb shell "echo 0 > /sys/kernel/debug/tracing/tracing_on"
rem erase previous recorded trace
adb shell "echo > /sys/kernel/debug/tracing/trace"
echo press any key to start capturing...
pause

adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_on"

echo "Start recordng ftrace data"
echo "Press any key to stop..."
pause

adb shell "echo 0 > /sys/kernel/debug/tracing/tracing_on"
echo "Recording stopped..."
adb pull /sys/kernel/debug/tracing/trace SYS_FTRACE
adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_on"
echo "Please copy SYS_FTRACE to ftrace_all_in_one and press 02-parse.bat"
pause
