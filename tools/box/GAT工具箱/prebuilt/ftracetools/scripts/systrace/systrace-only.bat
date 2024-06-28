@echo off
@..\..\perl\perl.exe -I..\..\perl\lib\mediatek ..\..\perl\trim_events.pl < SYS_FTRACE > SYS_FTRACE.trimmed.log
@..\..\perl\perl.exe ..\..\perl\trim_tgid.pl < SYS_FTRACE.trimmed.log | ..\..\perl\perl.exe -I..\..\perl\lib\mediatek ..\..\perl\convert2systrace.4_4+gpu_parser.pl > trace.html
@del SYS_FTRACE.trimmed.log
pause
