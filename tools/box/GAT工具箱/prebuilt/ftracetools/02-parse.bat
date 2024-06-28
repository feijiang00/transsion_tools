@echo off
@.\perl\perl.exe .\perl\fix_cmd.pl SYS_FTRACE
@.\perl\perl.exe -I.\perl\lib\mediatek .\perl\trim_events.pl < SYS_FTRACE > SYS_FTRACE.trimmed.log
@.\perl\perl.exe -I.\perl\lib\mediatek .\perl\convert2vcd.pl SYS_FTRACE.trimmed.log trace.vcd
@.\perl\perl.exe -I.\perl\lib\mediatek .\perl\ftrace_cputime.pl SYS_FTRACE.trimmed.log ftrace_cputime.csv
@.\perl\perl.exe .\perl\trim_tgid.pl < SYS_FTRACE.trimmed.log > SYS_FTRACE.trimmed.trim_tgid.log 
@.\perl\perl.exe -I.\perl\lib\mediatek .\perl\convert2systrace.pl SYS_FTRACE.trimmed.trim_tgid.log trace.html
rem @.\perl\perl.exe -I.\perl\lib\mediatek .\perl\ftrace_loading.pl SYS_FTRACE.trimmed.log ftrace_
@del SYS_FTRACE.trimmed.log SYS_FTRACE.trimmed.trim_tgid.log

start .\gtkwave\bin\gtkwave.exe trace.vcd
pause
