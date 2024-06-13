@echo off

adb shell "echo 3 > /proc/sys/vm/drop_caches" >nul 2>&1
adb shell "echo 16384 > /sys/kernel/debug/tracing/buffer_size_kb"
echo "buffer_size_kb(per cpu): "
adb shell "cat /sys/kernel/debug/tracing/buffer_size_kb"
adb shell "echo nop > /sys/kernel/debug/tracing/current_tracer" >nul 2>&1
adb shell "echo 'norecord-cmd noprint-tgid' > /sys/kernel/debug/tracing/trace_options" >nul 2>&1
rem adb shell "echo 'noirq-info' > /sys/kernel/debug/tracing/trace_options"
adb shell "echo 'sched_switch sched_wakeup sched_wakeup_new sched_migrate_task softirq_raise softirq_entry softirq_exit cpu_frequency workqueue_execute_start workqueue_execute_end block_bio_frontmerge block_bio_backmerge block_rq_issue block_rq_insert block_rq_complete mtk_events' > /sys/kernel/debug/tracing/set_event"
rem adb shell 'echo irq_handler_entry irq_handler_exit >> /sys/kernel/debug/tracing/set_event'
rem adb shell "echo 'sched_switch sched_wakeup sched_wakeup_new sched_migrate_task cpu_frequency ' > /sys/kernel/debug/tracing/set_event"
rem just in case tracing_enabled is disabled by user or other debugging tool
adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_enabled" >nul 2>&1
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
adb shell cat /sys/kernel/debug/tracing/trace > SYS_FTRACE
adb shell "echo norecord-cmd > /sys/kernel/debug/tracing/trace_options" >nul 2>&1
adb shell "echo noprint-tgid > /sys/kernel/debug/tracing/trace_options" >nul 2>&1
adb shell "echo 1 > /sys/kernel/debug/tracing/tracing_on"
echo "Please press 02-parse.bat to analyze it with gtkwave and csv file"
pause
