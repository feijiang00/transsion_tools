::pull log for transsion by xingui.yang
adb wait-for-device & adb root
adb wait-for-device
for /F %%i in ('adb shell getprop ro.serialno') do ( set sn=%%i)
for /F %%i in ('adb shell getprop ro.vendor.version.release') do ( set version=%%i)
for /F %%i in ('adb shell getprop ro.build.product') do ( set product=%%i)
for /F %%i in ('adb shell getprop ro.build.type') do ( set buildtype=%%i)
set hm=%time:~0,5%
set hm=%hm::=%
set hm=%hm: =0%
set itellog=itellog_%product%%buildtype%_%version%_%sn%_%date:~0,4%%date:~5,2%%date:~8,2%%hm%
set mtk=mt
:: mtk platform
for /F %%i in ('adb shell getprop ro.hardware') do ( set hardware=%%i)
if %hardware:~0,2% == %mtk% (
md %itellog%\mtklog
adb shell cp -R /data/vendor/mtklog/aee_exp/*  /sdcard/data_vendor_aee_exp/ 
adb pull /data/aee_exp %itellog%\mtklog\data_aee_exp
adb pull /storage/sdcard0/mtklog %itellog%\mtklog\mtklog
adb pull /storage/sdcard1/mtklog %itellog%\mtklog\mtklog
adb pull /tranfs/SI1/exception.txt %itellog%\mtklog\exception.txt
adb pull /data/aee_exp %itellog%\mtklog\data_aee_exp
    
adb shell mkdir /sdcard/data_vendor_aee_exp
adb shell cp -R /data/vendor/mtklog/aee_exp/*  /sdcard/data_vendor_aee_exp/
adb pull /sdcard/data_vendor_aee_exp %itellog%\mtklog\data_vendor_aee_exp
adb shell rm -rf /sdcard/data_vendor_aee_exp
    
adb pull /data/anr %itellog%\mtklog\anr
adb pull /data/mobilelog %itellog%\mtklog\data_mobilelog
adb pull /data/core %itellog%\mtklog\data_core
adb pull /data/tombstones %itellog%\mtklog\data_tombstones
adb pull /data/vendor/tombstones %itellog%\mtklog\data_vendor_tombstones
adb pull /data/recovery %itellog%\mtklog\recovery
adb pull /data/rtt_dump* %itellog%\mtklog\mtklog\sf_dump
adb pull /data/anr/sf_rtt %itellog%\mtklog\mtklog\sf_rtt_1
adb pull /storage/sdcard0/debuglogger %itellog%\mtklog\debuglogger
adb pull /storage/sdcard1/debuglogger %itellog%\mtklog\debuglogger
) else (
md %itellog%\ylog
adb shell ylogctl enable
adb shell log_ctr setprop  persist.sys.ylog.enabled 1
adb shell ylog_cli ylog android start 
adb shell ylog_cli ylog kernel start
adb shell echo 0 > /sys/class/misc/sprd_7sreset/hard_mode
adb shell setprop debug.sysdump.enabled true
adb shell setprop debug.corefile.enabled true
adb shell echo "on" > /proc/sprd_sysdump
adb pull  /data/minidump %itellog%\ylog\minidump
adb pull  /data/minidump2 %itellog%\ylog\minidump
adb pull  /sdcard/minidump %itellog%\ylog\minidump
adb pull  /sdcard/minidump2 %itellog%\ylog\minidump
adb pull  /data/smartsystem/smartbugrt/release  %itellog%\smartbugrt
adb pull  /data/tombstones %itellog%\ylog\
adb pull /data/corefile %itellog%\ylog\
if exist %itellog%\ylog\minidump copy parse_minidump.py %itellog%\ylog\minidump\1
adb pull  /sdcard/ylog %itellog%\ylog\ylog
adb pull  /storage/sdcard0/ylog/ %itellog%\ylog\sd_ylog
adb pull /data/ylog %itellog%\ylog\data_ylog
)

md %itellog%\sys_info
adb pull /sdcard/monkey.txt %itellog%\sys_info\monkey.txt
adb pull /sdcard/monkeyerror.txt  %itellog%\sys_info\monkeyerror.txt
adb shell dumpsys SurfaceFlinger > %itellog%\sys_info\dumpsys_SurfaceFlinger.txt
adb shell cat /d/tracing/trace > %itellog%\sys_info\d_tracing_trace.txt
adb shell cat /d/sync > %itellog%\sys_info\d_sync.txt
adb shell ps -A > %itellog%\sys_info\ps_A.txt
adb shell free>%itellog%\sys_info\free
adb shell df>%itellog%\sys_info\df
adb shell cat /proc/meminfo>%itellog%\sys_info\meminfo
adb shell cat /proc/zoneinfo>%itellog%\sys_info\zoneinfo
adb shell cat /proc/interrupts>%itellog%\sys_info\interrupts
adb shell getprop > %itellog%\sys_info\prop
adb shell ps -A > %itellog%\sys_info\process_info
adb shell dumpsys activity activities > %itellog%\sys_info\dumpsys_activity
adb shell dumpsys>%itellog%\sys_info\dumpsys
adb pull /data/diagnosed/ %itellog%\sys_info\diagnosed
adb pull  /data/anr %itellog%\data_anr
adb shell bugreportz -c
adb pull /data/usercorefile %itellog%\ylog\
adb shell top -s 7 -m 100 -n 5 > %itellog%\sys_info\top
adb bugreport bugreport.zip
move bugreport.zip %itellog%\ylog\
adb shell screencap -p /sdcard/screencap.png
adb pull /sdcard/screencap.png  %itellog%\sys_info\screencap.png
adb shell rm /sdcard/screencap.png

pause