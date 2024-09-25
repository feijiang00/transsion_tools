echo off
MODE con: COLS=65 LINES=50
TITLE 三方测试adb工具
color 8f
:STARTS 
CLS
ECHO.                           ADB工具箱V1.3   
ECHO                                                   -@test3bai
ECHO. =============================================================
ECHO. 功能选择（输入相对应的序号按回车键确认）：
ECHO. =============================================================
ECHO. 
ECHO.     -测试命令-                         -连接状态-
ECHO. 1.截屏并导出                     100.查看当前连接的设备
ECHO. 2.录屏并导出                     101.切换连接设备
ECHO. 3.打开系统设置                   102.重新挂载文件
ECHO. 4.从PC传到手机                   
ECHO. 5.开启指针                             -设备状态-
ECHO. 6.查看OSpath版本                 131.查看设备型号信息
ECHO. 7.查看systemUI版本号             132.查看imei
ECHO. 8.查询版本类型                   133.开关wifi   
ECHO. 9.查询GMS版本                    134.蓝牙地址
ECHO. 10.查询是否写入googleKey         135.重启手机         
ECHO. 11.查OOBE国家                    136.关闭手机 
ECHO. 12.填充内存                      137.屏幕分辨率与密度查询
ECHO. 13.杀死双开助手                  138.屏幕分辨率与密度设置
ECHO.                                  139.屏幕分辨率与密度恢复
ECHO.     -三方命令-                   140.查看系统应用
ECHO. 31.依据用例包名安装（GP）        141.查看三方应用（All）
ECHO. 32.依据用例包名安装（Other）     142.查看三方应用及安装来源
ECHO. 38.根据包名下载应用（All）       143.开关防误触       
ECHO. 35.强制安装应用                  144.设置休眠时间30分钟
ECHO. 37.查看前台活动和包名            
ECHO. 39.查看应用位置并导出                  -应急命令-
ECHO. 42.批量安装apk                   161.锁屏失效，模拟滑动解锁
ECHO. 33.测试资源一键配置              162.应用卡住清除数据和缓存
ECHO. 36.开启记事本录音                163.锁屏密码弹不出键盘
ECHO. 34.强制停止应用                  164.屏幕极暗恢复亮度
ECHO. 40.触发低电量及恢复              165.文本输入
ECHO. 41.查看应用是32or64位            166.电源键失效
ECHO.                                  167.T卡升级电量不够  
ECHO.     -常用log命令-         
ECHO. 61.导出Ylog（全）         
ECHO. 62.打开debuglogUI         
ECHO. 63.导出Audiolog及清理     
ECHO. 66.窗口、显示问题 log       
ECHO. 65.导log时出问题 log      
ECHO. 90.清空全log     
ECHO. 64.打开Launcher log
ECHO.                                                        
ECHO. =============================================================
:CHO
set choice= 
set /p choice=输入对应数字，然后按回车键:
if /i "%choice%"=="1" goto 1
if /i "%choice%"=="2" goto 2
if /i "%choice%"=="3" goto 3
if /i "%choice%"=="4" goto 4
if /i "%choice%"=="5" goto 5
if /i "%choice%"=="6" goto 6
if /i "%choice%"=="7" goto 7
if /i "%choice%"=="8" goto 8
if /i "%choice%"=="9" goto 9
if /i "%choice%"=="10" goto 10
if /i "%choice%"=="11" goto 11
if /i "%choice%"=="12" goto 12
if /i "%choice%"=="13" goto 13
if /i "%choice%"=="14" goto 14
if /i "%choice%"=="15" goto 15
if /i "%choice%"=="16" goto 16
if /i "%choice%"=="17" goto 17
if /i "%choice%"=="18" goto 18
if /i "%choice%"=="19" goto 19
if /i "%choice%"=="20" goto 20
if /i "%choice%"=="21" goto 21
if /i "%choice%"=="22" goto 22
if /i "%choice%"=="23" goto 23
if /i "%choice%"=="24" goto 24
if /i "%choice%"=="25" goto 25
if /i "%choice%"=="26" goto 26
if /i "%choice%"=="27" goto 27
if /i "%choice%"=="28" goto 28
if /i "%choice%"=="29" goto 29
if /i "%choice%"=="30" goto 30
if /i "%choice%"=="31" goto 31
if /i "%choice%"=="32" goto 32
if /i "%choice%"=="33" goto 33
if /i "%choice%"=="34" goto 34
if /i "%choice%"=="35" goto 35
if /i "%choice%"=="36" goto 36
if /i "%choice%"=="37" goto 37
if /i "%choice%"=="38" goto 38
if /i "%choice%"=="39" goto 39
if /i "%choice%"=="40" goto 40
if /i "%choice%"=="41" goto 41
if /i "%choice%"=="42" goto 42
if /i "%choice%"=="43" goto 43
if /i "%choice%"=="44" goto 44
if /i "%choice%"=="45" goto 45
if /i "%choice%"=="46" goto 46
if /i "%choice%"=="47" goto 47
if /i "%choice%"=="48" goto 48
if /i "%choice%"=="49" goto 49
if /i "%choice%"=="50" goto 50
if /i "%choice%"=="51" goto 51
if /i "%choice%"=="52" goto 52
if /i "%choice%"=="53" goto 53
if /i "%choice%"=="54" goto 54
if /i "%choice%"=="55" goto 55
if /i "%choice%"=="56" goto 56
if /i "%choice%"=="57" goto 57
if /i "%choice%"=="58" goto 58
if /i "%choice%"=="59" goto 59
if /i "%choice%"=="60" goto 60
if /i "%choice%"=="61" goto 61
if /i "%choice%"=="62" goto 62
if /i "%choice%"=="63" goto 63
if /i "%choice%"=="64" goto 64
if /i "%choice%"=="65" goto 65
if /i "%choice%"=="66" goto 66
if /i "%choice%"=="67" goto 67
if /i "%choice%"=="68" goto 68
if /i "%choice%"=="69" goto 69
if /i "%choice%"=="70" goto 70
if /i "%choice%"=="71" goto 71
if /i "%choice%"=="72" goto 72
if /i "%choice%"=="73" goto 73
if /i "%choice%"=="74" goto 74
if /i "%choice%"=="75" goto 75
if /i "%choice%"=="76" goto 76
if /i "%choice%"=="77" goto 77
if /i "%choice%"=="78" goto 78
if /i "%choice%"=="79" goto 79
if /i "%choice%"=="80" goto 80
if /i "%choice%"=="81" goto 81
if /i "%choice%"=="82" goto 82
if /i "%choice%"=="83" goto 83
if /i "%choice%"=="84" goto 84
if /i "%choice%"=="85" goto 85
if /i "%choice%"=="86" goto 86
if /i "%choice%"=="87" goto 87
if /i "%choice%"=="88" goto 88
if /i "%choice%"=="89" goto 89
if /i "%choice%"=="90" goto 90
if /i "%choice%"=="91" goto 91
if /i "%choice%"=="92" goto 92
if /i "%choice%"=="93" goto 93
if /i "%choice%"=="94" goto 94
if /i "%choice%"=="95" goto 95
if /i "%choice%"=="96" goto 96
if /i "%choice%"=="97" goto 97
if /i "%choice%"=="98" goto 98
if /i "%choice%"=="99" goto 99
if /i "%choice%"=="100" goto 100
if /i "%choice%"=="101" goto 101
if /i "%choice%"=="102" goto 102
if /i "%choice%"=="103" goto 103
if /i "%choice%"=="104" goto 104
if /i "%choice%"=="105" goto 105
if /i "%choice%"=="106" goto 106
if /i "%choice%"=="107" goto 107
if /i "%choice%"=="108" goto 108
if /i "%choice%"=="109" goto 109
if /i "%choice%"=="110" goto 110
if /i "%choice%"=="111" goto 111
if /i "%choice%"=="112" goto 112
if /i "%choice%"=="113" goto 113
if /i "%choice%"=="114" goto 114
if /i "%choice%"=="115" goto 115
if /i "%choice%"=="116" goto 116
if /i "%choice%"=="117" goto 117
if /i "%choice%"=="118" goto 118
if /i "%choice%"=="119" goto 119
if /i "%choice%"=="120" goto 120
if /i "%choice%"=="121" goto 121
if /i "%choice%"=="122" goto 122
if /i "%choice%"=="123" goto 123
if /i "%choice%"=="124" goto 124
if /i "%choice%"=="125" goto 125
if /i "%choice%"=="126" goto 126
if /i "%choice%"=="127" goto 127
if /i "%choice%"=="128" goto 128
if /i "%choice%"=="129" goto 129
if /i "%choice%"=="130" goto 130
if /i "%choice%"=="131" goto 131
if /i "%choice%"=="132" goto 132
if /i "%choice%"=="133" goto 133
if /i "%choice%"=="134" goto 134
if /i "%choice%"=="135" goto 135
if /i "%choice%"=="136" goto 136
if /i "%choice%"=="137" goto 137
if /i "%choice%"=="138" goto 138
if /i "%choice%"=="139" goto 139
if /i "%choice%"=="140" goto 140
if /i "%choice%"=="141" goto 141
if /i "%choice%"=="142" goto 142
if /i "%choice%"=="143" goto 143
if /i "%choice%"=="144" goto 144
if /i "%choice%"=="145" goto 145
if /i "%choice%"=="146" goto 146
if /i "%choice%"=="147" goto 147
if /i "%choice%"=="148" goto 148
if /i "%choice%"=="149" goto 149
if /i "%choice%"=="150" goto 150
if /i "%choice%"=="151" goto 151
if /i "%choice%"=="152" goto 152
if /i "%choice%"=="153" goto 153
if /i "%choice%"=="154" goto 154
if /i "%choice%"=="155" goto 155
if /i "%choice%"=="156" goto 156
if /i "%choice%"=="157" goto 157
if /i "%choice%"=="158" goto 158
if /i "%choice%"=="159" goto 159
if /i "%choice%"=="160" goto 160
if /i "%choice%"=="161" goto 161
if /i "%choice%"=="162" goto 162
if /i "%choice%"=="163" goto 163
if /i "%choice%"=="164" goto 164
if /i "%choice%"=="165" goto 165
if /i "%choice%"=="166" goto 166
if /i "%choice%"=="167" goto 167

echo 选择无效，请重新输入
:0
CLS
@echo off
echo 选择无效，请重新输入
pause
GOTO STARTS
:100
CLS
@echo off
adb devices
echo 左侧为设备序列号，右侧为设备
pause
GOTO STARTS
:101
CLS
@echo off
adb devices
echo 左侧为设备序列号，右侧为设备
set /p a1=请输入需要使用adb的设备序列号:
adb -s %a%
echo 设备 %a% 已连接
pause
GOTO STARTS
:102
CLS
@echo on
adb root
adb remount
@echo off
pause
GOTO STARTS
:131
CLS
@echo on
adb shell getprop ro.product.model
@echo off
pause
GOTO STARTS
:132
CLS
@echo on
adb shell dumpsys iphonesubinfo
@echo off
pause
GOTO STARTS
:133
CLS
@echo off
set /p a=开启输入enable，关闭输入disable：
adb shell svc wifi %a%
echo wifi状态：%a%
pause
GOTO STARTS
:134
CLS
@echo on
adb shell settings get secure bluetooth_address
@echo off
pause
GOTO STARTS
:135
CLS
@echo on
adb reboot
@echo off
pause
GOTO STARTS
:136
CLS
@echo on
adb shell reboot -p
@echo off
pause
GOTO STARTS
:137
CLS
adb shell wm size
adb shell wm density
pause
GOTO STARTS
:138
CLS
@echo off
set /p a=请先输入分辨率(格式为720x1280):
set /p b=请先输入DPI:
adb shell wm size %a%
adb shell wm density %b%
pause
GOTO STARTS
:139
CLS
adb shell wm size reset
adb shell wm density reset
GOTO STARTS
:140
CLS
adb shell pm list packages -s
pause
GOTO STARTS
:141
CLS
adb shell pm list packages -3
pause
GOTO STARTS
:142
CLS
@echo off
adb shell pm list packages -i -3
pause
GOTO STARTS
:143
CLS
@echo off
set /p a=关闭输0，开启输1：
adb shell settings put system show_inadvertent %a%
pause
GOTO STARTS
:144
CLS
adb shell settings put system screen_off_timeout 1800000
pause
GOTO STARTS
:161
CLS
adb shell input swipe 300 1000 300 500
pause
GOTO STARTS
:162
CLS
@echo off
echo 双清等于将应用恢复成初始状态，可作用于三方/系统应用
set /p a=粘贴想清理的应用的包名：
adb shell pm clear %a%
pause
GOTO STARTS
:163
CLS
@echo off
echo 目前支持解锁密码“1234”，请保存手机屏幕点亮，且选中密码输入框的状态
adb shell input keyevent 8
adb shell input keyevent 9
adb shell input keyevent 10
adb shell input keyevent 11
adb shell input keyevent 66
echo 执行完毕
pause
GOTO STARTS
:164
CLS
@echo off
adb shell settings put system screen_brightness_mode 0
adb shell settings put system screen_brightness 100
echo 已关闭自动调节亮度，并将亮度拉满
pause
GOTO STARTS
:165
CLS
@echo off
set /p a=输入你想在手机文本框输入的内容：
adb shell input text %a%
pause
GOTO STARTS
:166
CLS
@echo off
echo 模拟按一次电源键
adb shell input keyevent 26
pause
GOTO STARTS
:167
CLS
@echo off
echo 中途断电有死机风险，真实电量过低不要使用，T卡中保持充电状态
pause
adb shell dumpsys battery set level 100
echo "按任意按键，恢复电源原状态"
pause
adb shell dumpsys battery reset
pause
GOTO STARTS



:1
CLS
@echo off
set a=%Date:~0,4%%date:~5,2%%date:~8,2%%hm%-%Time:~0,2%%Time:~3,2%-%Time:~6,2%
adb shell screencap /sdcard/%a%.png
adb pull /sdcard/%a%.png .
echo 已导出截图到本目录，原图位于手机根目录
pause
GOTO STARTS
:2
CLS
@echo off
set a=%Date:~0,4%%date:~5,2%%date:~8,2%%hm%-%Time:~0,2%%Time:~3,2%-%Time:~6,2%
echo 按CTRL+C停止录像，在弹出的询问“终止批处理操作（Y/N）”时，输入n，即可导出视频至当前目录
adb shell screenrecord --bugreport /sdcard/%a%.mp4
adb remount
adb pull /sdcard/%a%.mp4 .
echo 已导出视频到本目录，原视频位于手机根目录
pause
GOTO STARTS
:3
CLS
adb shell am start -a android.settings.SETTINGS 
pause
GOTO STARTS
:4
CLS
@echo off
adb remount
set /p a=要传输的文件（把文件或文件夹拖到此处，自动获取地址）：
adb push %a% /sdcard/
echo 文件位于手机根目录
pause
GOTO STARTS
:5
CLS
adb shell settings put system pointer_location 1
pause
GOTO STARTS
:6
CLS
adb shell getprop ro.os.version.release
pause
GOTO STARTS
:7
CLS
adb shell dumpsys package com.android.systemui | findstr  version
pause
GOTO STARTS
:8
CLS
adb shell getprop | findstr ro.build.type
pause
GOTO STARTS
:9
CLS
adb shell getprop ro.com.google.gmsversion
pause
GOTO STARTS
:10
CLS
adb shell getprop | findstr -rin googlekey
adb shell getprop soter.teei.googlekey.status
adb shell getprop vendor.tee.googlekey.status
pause
GOTO STARTS
:11
CLS
adb shell getprop | findstr oobe
adb shell getprop | find "persist.sys.oobe_country" 
pause
GOTO STARTS
:12
CLS
@echo off
set /p a=输入文件名:
echo 文件会保存在系统根目录（%a%.bstc），取不同的名字可以随意增删，不然新的会覆盖之前的
set /p b=想填多少个g就写多少（写数字，不能小于1）:
echo 正在填充，耗时操作，耐心等待
adb shell "cd sdcard;dd if=/dev/zero bs=1024000000 count=%b% of=%a%.bstc"
pause
GOTO STARTS
:13
CLS
adb shell pm remove-user 999
pause
GOTO STARTS
:31
CLS
ECHO.
ECHO. =============================================================
ECHO. 专项选择（输入对应的序号按回车键确认）：
ECHO. =============================================================
ECHO.
ECHO. 1.三方launcher交互          10.viberMessenger
ECHO. 2.游戏模式                  11.三方外发用例
ECHO. 3.社交通讯专项              12.用户环境
ECHO. 4.音频交互                  13.RU PIA推送App
ECHO. 5.视频交互                  14.视频助手
ECHO. 6.用户环境                  15.小分类用例
ECHO. 7.应用双开                  16.闪电多窗
ECHO. 8.GPU 专项                  17.GameLife
ECHO. 9.TranBookmarks             18.输入法交互专项
ECHO. 0.自定义
ECHO. 
ECHO. =============================================================
@echo off
set /p a=输入对应数字，然后按回车键:
for /f %%i in ('type .\用例包名\%a%\pkg.txt ') do (
  echo %%i
  adb shell am start -n com.android.vending/.AssetBrowserActivity -a android.intent.action.VIEW -d market://details?id=%%i
  echo “请按任意键跳转下一条”
  pause
)
echo 本包名遍历完毕了
pause
GOTO STARTS
:32
CLS
ECHO.
ECHO. =============================================================
ECHO. 专项选择（输入对应的序号按回车键确认）：
ECHO. =============================================================
ECHO.
ECHO. 1.三方launcher交互          10.viberMessenger
ECHO. 2.游戏模式                  11.三方外发用例
ECHO. 3.社交通讯专项              12.用户环境
ECHO. 4.音频交互                  13.RU PIA推送App
ECHO. 5.视频交互                  14.视频助手
ECHO. 6.用户环境                  15.小分类用例
ECHO. 7.应用双开                  16.闪电多窗
ECHO. 8.GPU 专项                  17.GameLife
ECHO. 9.TranBookmarks             18.输入法交互专项
ECHO. 0.自定义
ECHO. 
ECHO. =============================================================
@echo off
set /p a=输入对应数字，然后按回车键:
for /f %%i in ('type .\用例包名\%a%\pkg.txt ') do (
  echo %%i
  adb shell am start -a android.intent.action.VIEW -d market://details?id=%%i
  echo “请按任意键跳转下一条”
  pause
)
echo 本包名遍历完毕了
pause
GOTO STARTS
:33
CLS
@echo off
adb remount
echo 文件必须是英文名，如果是中文会导入乱码文件，先退出，改名后再导入
pause
adb push .\pushFiles /sdcard/
echo 文件位于手机根目录
pause
GOTO STARTS
:34
CLS
@echo off
set /p a=粘贴包名后回车:
adb shell am force-stop %a%
pause
GOTO STARTS
:35
CLS
@echo off
set /p a=将安装包拖到此处后回车:
adb install -r -t -d %a%
pause
GOTO STARTS
:36
CLS
adb shell content query --uri content://com.hoffnung.cloudControl.RemoteConfigProvider/config/_test
pause
GOTO STARTS
:37
CLS
adb shell dumpsys window | findstr mCurrentFocus
pause
GOTO STARTS
:38
CLS
@echo off
set /p a=粘贴包名后回车:
adb shell am start -a android.intent.action.VIEW -d market://details?id=%a%
pause
GOTO STARTS
:39
CLS
@echo off
set /p a=粘贴包名后回车:
adb shell pm path %a%
set /p b=复制并粘贴package的路径，敲回车:
adb pull %b% .
pause
GOTO STARTS
:40
CLS
adb shell dumpsys battery set status 1
adb shell dumpsys battery set level 41
adb shell dumpsys battery set level 40
adb shell dumpsys battery set level 39
adb shell dumpsys battery set level 38
adb shell dumpsys battery set level 37
adb shell dumpsys battery set level 36
adb shell dumpsys battery set level 35
adb shell dumpsys battery set level 34
adb shell dumpsys battery set level 33
adb shell dumpsys battery set level 32
adb shell dumpsys battery set level 31
adb shell dumpsys battery set level 30
adb shell dumpsys battery set level 29
adb shell dumpsys battery set level 28
adb shell dumpsys battery set level 27
adb shell dumpsys battery set level 26
adb shell dumpsys battery set level 25
adb shell dumpsys battery set level 24
adb shell dumpsys battery set level 23
adb shell dumpsys battery set level 22
adb shell dumpsys battery set level 21
adb shell dumpsys battery set level 20
adb shell dumpsys battery set level 19
adb shell dumpsys battery set level 18
adb shell dumpsys battery set level 17
adb shell dumpsys battery set level 16
adb shell dumpsys battery set level 15
adb shell dumpsys battery set level 14
adb shell dumpsys battery set level 13
adb shell dumpsys battery set level 12
adb shell dumpsys battery set level 11
adb shell dumpsys battery set level 10
adb shell dumpsys battery set level 9
@echo off
echo "按任意按键，恢复电源原状态"
pause
adb shell dumpsys battery reset
echo 执行完毕
pause
GOTO STARTS
:41
CLS
@echo off
set /p a=粘贴包名后回车:
adb shell "dumpsys package %a% | findstr "primaryCpuAbi"
echo 输出 armeabi-v7a或者armeabi 为 32位
echo 输出 arm64-v8a              为 64位
pause
GOTO STARTS
:42
CLS
@echo off
cd .\批量安装
for %%i in (*.apk) do (   
    echo 正在安装：%%i  
    adb install "%%i"  
    )  
echo 安装完毕
pause
GOTO STARTS
:61
CLS
@echo off
echo 现在拉起Ylog脚本
cd /d .\deviceLogs
call ExportLogFiles_Ylog.bat
echo Ylog文件保存在 测试ADB工具箱\deviceLogs 中
pause
GOTO STARTS
:62
CLS
adb shell am start -n com.debug.loggerui/.MainActivity
pause
GOTO STARTS
:63
CLS
@echo off
echo 现在拉起AudioLog脚本
cd /d .\audioLogs
call ExporAudiolog.bat
echo Audiolog文件保存在 测试ADB工具箱\audioLogs 中
pause
GOTO STARTS
:64
CLS
adb shell setprop log.tag.Launcher V
pause
GOTO STARTS
:65
CLS
adb shell logcat
pause
GOTO STARTS
:66
CLS
ECHO.
ECHO. =============================================================
ECHO. 场景选择（输入对应的序号按回车键确认）：
ECHO. =============================================================
ECHO.
ECHO. 1.能够复现问题（问题复现前开启）         
ECHO. 2.问题已经出现（抓取当前界面能捕获的异常信息。并且会同时打开
ECHO.   wmslog，如果后续复现就可以抓全全部信息。）
ECHO.
ECHO. =============================================================
adb shell settings put system pointer_location  1
echo 显示类问题，已打开屏幕指针
set choice2= 
set /p choice2=输入对应数字，然后按回车键:
if /i "%choice2%"=="1" goto 301
if /i "%choice2%"=="2" goto 302
pause
GOTO STARTS
:67
CLS
此命令移除
pause
GOTO STARTS
:90
CLS
echo 在部分机器上会出现清理后，无法导出log的问题，慎重使用
echo 确定使用敲“任意键”，反之关闭窗口
pause
adb shell rm -rf data/aee_exp/*
adb logcat -c
pause
GOTO STARTS

:301
CLS
echo 问题出现前执行
adb root 
adb shell setprop sys.input.TouchFilterEnable true
adb shell setprop sys.input.TouchFilterLogEnable true
adb shell setprop sys.inputlog.enabled true
adb shell dumpsys window -d enable a
adb shell dumpsys activity log x on
echo .
echo .
echo .
echo .
echo . 
echo 开启wmslog的操作执行完毕
echo =============================================================
echo 请复现问题（完整复现后，在问题界面敲回车）
pause
set a=%Date:~0,4%%date:~5,2%%date:~8,2%%hm%-%Time:~0,2%%Time:~3,2%-%Time:~6,2%
md .\wmsLogs\wmslog_%a%
adb shell dumpsys SurfaceFlinger > .\wmsLogs\wmslog_%a%\sf.txt
adb shell dumpsys window -a > .\wmsLogs\wmslog_%a%\window1.txt
adb shell dumpsys display > .\wmsLogs\wmslog_%a%\display1.txt
echo 捕获的异常信息在\wmsLogs\wmslog_%a%，提交bug时需连同 mtklog、视频一并提交 
pause
GOTO STARTS
:302
CLS
echo 问题出现时执行
adb root 
set a=%Date:~0,4%%date:~5,2%%date:~8,2%%hm%-%Time:~0,2%%Time:~3,2%-%Time:~6,2%
md .\wmsLogs\wmslog_%a%
adb shell setprop sys.input.TouchFilterEnable true
adb shell setprop sys.input.TouchFilterLogEnable true
adb shell setprop sys.inputlog.enabled true
adb shell dumpsys window -d enable a
adb shell dumpsys activity log x on
adb shell dumpsys SurfaceFlinger > .\wmsLogs\wmslog_%a%\sf.txt
adb shell dumpsys window -a > .\wmsLogs\wmslog_%a%\window1.txt
adb shell dumpsys display > .\wmsLogs\wmslog_%a%\display1.txt
echo .
echo .
echo .
echo .
echo .
echo 开启wmslog的操作执行完毕
echo =============================================================
echo 捕获的异常信息在\wmsLogs\wmslog_%a%
echo 如果后续再次复现，再执行一次并命令，并提供捕获文件和mobile log，即可抓全（如果已经复现执行过一次，忽视此条）
echo 提交bug时，需要完整提交 mtklog、视频、上述捕获 
pause
GOTO STARTS



