echo off
MODE con: COLS=65 LINES=50
TITLE ��������adb����
color 8f
:STARTS 
CLS
ECHO.                           ADB������V1.3   
ECHO                                                   -@test3bai
ECHO. =============================================================
ECHO. ����ѡ���������Ӧ����Ű��س���ȷ�ϣ���
ECHO. =============================================================
ECHO. 
ECHO.     -��������-                         -����״̬-
ECHO. 1.����������                     100.�鿴��ǰ���ӵ��豸
ECHO. 2.¼��������                     101.�л������豸
ECHO. 3.��ϵͳ����                   102.���¹����ļ�
ECHO. 4.��PC�����ֻ�                   
ECHO. 5.����ָ��                             -�豸״̬-
ECHO. 6.�鿴OSpath�汾                 131.�鿴�豸�ͺ���Ϣ
ECHO. 7.�鿴systemUI�汾��             132.�鿴imei
ECHO. 8.��ѯ�汾����                   133.����wifi   
ECHO. 9.��ѯGMS�汾                    134.������ַ
ECHO. 10.��ѯ�Ƿ�д��googleKey         135.�����ֻ�         
ECHO. 11.��OOBE����                    136.�ر��ֻ� 
ECHO. 12.����ڴ�                      137.��Ļ�ֱ������ܶȲ�ѯ
ECHO. 13.ɱ��˫������                  138.��Ļ�ֱ������ܶ�����
ECHO.                                  139.��Ļ�ֱ������ܶȻָ�
ECHO.     -��������-                   140.�鿴ϵͳӦ��
ECHO. 31.��������������װ��GP��        141.�鿴����Ӧ�ã�All��
ECHO. 32.��������������װ��Other��     142.�鿴����Ӧ�ü���װ��Դ
ECHO. 38.���ݰ�������Ӧ�ã�All��       143.���ط���       
ECHO. 35.ǿ�ư�װӦ��                  144.��������ʱ��30����
ECHO. 37.�鿴ǰ̨��Ͱ���            
ECHO. 39.�鿴Ӧ��λ�ò�����                  -Ӧ������-
ECHO. 42.������װapk                   161.����ʧЧ��ģ�⻬������
ECHO. 33.������Դһ������              162.Ӧ�ÿ�ס������ݺͻ���
ECHO. 36.�������±�¼��                163.�������뵯��������
ECHO. 34.ǿ��ֹͣӦ��                  164.��Ļ�����ָ�����
ECHO. 40.�����͵������ָ�              165.�ı�����
ECHO. 41.�鿴Ӧ����32or64λ            166.��Դ��ʧЧ
ECHO.                                  167.T��������������  
ECHO.     -����log����-         
ECHO. 61.����Ylog��ȫ��         
ECHO. 62.��debuglogUI         
ECHO. 63.����Audiolog������     
ECHO. 66.���ڡ���ʾ���� log       
ECHO. 65.��logʱ������ log      
ECHO. 90.���ȫlog     
ECHO. 64.��Launcher log
ECHO.                                                        
ECHO. =============================================================
:CHO
set choice= 
set /p choice=�����Ӧ���֣�Ȼ�󰴻س���:
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

echo ѡ����Ч������������
:0
CLS
@echo off
echo ѡ����Ч������������
pause
GOTO STARTS
:100
CLS
@echo off
adb devices
echo ���Ϊ�豸���кţ��Ҳ�Ϊ�豸
pause
GOTO STARTS
:101
CLS
@echo off
adb devices
echo ���Ϊ�豸���кţ��Ҳ�Ϊ�豸
set /p a1=��������Ҫʹ��adb���豸���к�:
adb -s %a%
echo �豸 %a% ������
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
set /p a=��������enable���ر�����disable��
adb shell svc wifi %a%
echo wifi״̬��%a%
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
set /p a=��������ֱ���(��ʽΪ720x1280):
set /p b=��������DPI:
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
set /p a=�ر���0��������1��
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
echo ˫����ڽ�Ӧ�ûָ��ɳ�ʼ״̬��������������/ϵͳӦ��
set /p a=ճ���������Ӧ�õİ�����
adb shell pm clear %a%
pause
GOTO STARTS
:163
CLS
@echo off
echo Ŀǰ֧�ֽ������롰1234�����뱣���ֻ���Ļ��������ѡ������������״̬
adb shell input keyevent 8
adb shell input keyevent 9
adb shell input keyevent 10
adb shell input keyevent 11
adb shell input keyevent 66
echo ִ�����
pause
GOTO STARTS
:164
CLS
@echo off
adb shell settings put system screen_brightness_mode 0
adb shell settings put system screen_brightness 100
echo �ѹر��Զ��������ȣ�������������
pause
GOTO STARTS
:165
CLS
@echo off
set /p a=�����������ֻ��ı�����������ݣ�
adb shell input text %a%
pause
GOTO STARTS
:166
CLS
@echo off
echo ģ�ⰴһ�ε�Դ��
adb shell input keyevent 26
pause
GOTO STARTS
:167
CLS
@echo off
echo ��;�ϵ����������գ���ʵ�������Ͳ�Ҫʹ�ã�T���б��ֳ��״̬
pause
adb shell dumpsys battery set level 100
echo "�����ⰴ�����ָ���Դԭ״̬"
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
echo �ѵ�����ͼ����Ŀ¼��ԭͼλ���ֻ���Ŀ¼
pause
GOTO STARTS
:2
CLS
@echo off
set a=%Date:~0,4%%date:~5,2%%date:~8,2%%hm%-%Time:~0,2%%Time:~3,2%-%Time:~6,2%
echo ��CTRL+Cֹͣ¼���ڵ�����ѯ�ʡ���ֹ�����������Y/N����ʱ������n�����ɵ�����Ƶ����ǰĿ¼
adb shell screenrecord --bugreport /sdcard/%a%.mp4
adb remount
adb pull /sdcard/%a%.mp4 .
echo �ѵ�����Ƶ����Ŀ¼��ԭ��Ƶλ���ֻ���Ŀ¼
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
set /p a=Ҫ������ļ������ļ����ļ����ϵ��˴����Զ���ȡ��ַ����
adb push %a% /sdcard/
echo �ļ�λ���ֻ���Ŀ¼
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
set /p a=�����ļ���:
echo �ļ��ᱣ����ϵͳ��Ŀ¼��%a%.bstc����ȡ��ͬ�����ֿ���������ɾ����Ȼ�µĻḲ��֮ǰ��
set /p b=������ٸ�g��д���٣�д���֣�����С��1��:
echo ������䣬��ʱ���������ĵȴ�
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
ECHO. ר��ѡ�������Ӧ����Ű��س���ȷ�ϣ���
ECHO. =============================================================
ECHO.
ECHO. 1.����launcher����          10.viberMessenger
ECHO. 2.��Ϸģʽ                  11.�����ⷢ����
ECHO. 3.�罻ͨѶר��              12.�û�����
ECHO. 4.��Ƶ����                  13.RU PIA����App
ECHO. 5.��Ƶ����                  14.��Ƶ����
ECHO. 6.�û�����                  15.С��������
ECHO. 7.Ӧ��˫��                  16.����ര
ECHO. 8.GPU ר��                  17.GameLife
ECHO. 9.TranBookmarks             18.���뷨����ר��
ECHO. 0.�Զ���
ECHO. 
ECHO. =============================================================
@echo off
set /p a=�����Ӧ���֣�Ȼ�󰴻س���:
for /f %%i in ('type .\��������\%a%\pkg.txt ') do (
  echo %%i
  adb shell am start -n com.android.vending/.AssetBrowserActivity -a android.intent.action.VIEW -d market://details?id=%%i
  echo ���밴�������ת��һ����
  pause
)
echo ���������������
pause
GOTO STARTS
:32
CLS
ECHO.
ECHO. =============================================================
ECHO. ר��ѡ�������Ӧ����Ű��س���ȷ�ϣ���
ECHO. =============================================================
ECHO.
ECHO. 1.����launcher����          10.viberMessenger
ECHO. 2.��Ϸģʽ                  11.�����ⷢ����
ECHO. 3.�罻ͨѶר��              12.�û�����
ECHO. 4.��Ƶ����                  13.RU PIA����App
ECHO. 5.��Ƶ����                  14.��Ƶ����
ECHO. 6.�û�����                  15.С��������
ECHO. 7.Ӧ��˫��                  16.����ര
ECHO. 8.GPU ר��                  17.GameLife
ECHO. 9.TranBookmarks             18.���뷨����ר��
ECHO. 0.�Զ���
ECHO. 
ECHO. =============================================================
@echo off
set /p a=�����Ӧ���֣�Ȼ�󰴻س���:
for /f %%i in ('type .\��������\%a%\pkg.txt ') do (
  echo %%i
  adb shell am start -a android.intent.action.VIEW -d market://details?id=%%i
  echo ���밴�������ת��һ����
  pause
)
echo ���������������
pause
GOTO STARTS
:33
CLS
@echo off
adb remount
echo �ļ�������Ӣ��������������Ļᵼ�������ļ������˳����������ٵ���
pause
adb push .\pushFiles /sdcard/
echo �ļ�λ���ֻ���Ŀ¼
pause
GOTO STARTS
:34
CLS
@echo off
set /p a=ճ��������س�:
adb shell am force-stop %a%
pause
GOTO STARTS
:35
CLS
@echo off
set /p a=����װ���ϵ��˴���س�:
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
set /p a=ճ��������س�:
adb shell am start -a android.intent.action.VIEW -d market://details?id=%a%
pause
GOTO STARTS
:39
CLS
@echo off
set /p a=ճ��������س�:
adb shell pm path %a%
set /p b=���Ʋ�ճ��package��·�����ûس�:
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
echo "�����ⰴ�����ָ���Դԭ״̬"
pause
adb shell dumpsys battery reset
echo ִ�����
pause
GOTO STARTS
:41
CLS
@echo off
set /p a=ճ��������س�:
adb shell "dumpsys package %a% | findstr "primaryCpuAbi"
echo ��� armeabi-v7a����armeabi Ϊ 32λ
echo ��� arm64-v8a              Ϊ 64λ
pause
GOTO STARTS
:42
CLS
@echo off
cd .\������װ
for %%i in (*.apk) do (   
    echo ���ڰ�װ��%%i  
    adb install "%%i"  
    )  
echo ��װ���
pause
GOTO STARTS
:61
CLS
@echo off
echo ��������Ylog�ű�
cd /d .\deviceLogs
call ExportLogFiles_Ylog.bat
echo Ylog�ļ������� ����ADB������\deviceLogs ��
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
echo ��������AudioLog�ű�
cd /d .\audioLogs
call ExporAudiolog.bat
echo Audiolog�ļ������� ����ADB������\audioLogs ��
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
ECHO. ����ѡ�������Ӧ����Ű��س���ȷ�ϣ���
ECHO. =============================================================
ECHO.
ECHO. 1.�ܹ��������⣨���⸴��ǰ������         
ECHO. 2.�����Ѿ����֣�ץȡ��ǰ�����ܲ�����쳣��Ϣ�����һ�ͬʱ��
ECHO.   wmslog������������־Ϳ���ץȫȫ����Ϣ����
ECHO.
ECHO. =============================================================
adb shell settings put system pointer_location  1
echo ��ʾ�����⣬�Ѵ���Ļָ��
set choice2= 
set /p choice2=�����Ӧ���֣�Ȼ�󰴻س���:
if /i "%choice2%"=="1" goto 301
if /i "%choice2%"=="2" goto 302
pause
GOTO STARTS
:67
CLS
�������Ƴ�
pause
GOTO STARTS
:90
CLS
echo �ڲ��ֻ����ϻ����������޷�����log�����⣬����ʹ��
echo ȷ��ʹ���á������������֮�رմ���
pause
adb shell rm -rf data/aee_exp/*
adb logcat -c
pause
GOTO STARTS

:301
CLS
echo �������ǰִ��
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
echo ����wmslog�Ĳ���ִ�����
echo =============================================================
echo �븴�����⣨�������ֺ�����������ûس���
pause
set a=%Date:~0,4%%date:~5,2%%date:~8,2%%hm%-%Time:~0,2%%Time:~3,2%-%Time:~6,2%
md .\wmsLogs\wmslog_%a%
adb shell dumpsys SurfaceFlinger > .\wmsLogs\wmslog_%a%\sf.txt
adb shell dumpsys window -a > .\wmsLogs\wmslog_%a%\window1.txt
adb shell dumpsys display > .\wmsLogs\wmslog_%a%\display1.txt
echo ������쳣��Ϣ��\wmsLogs\wmslog_%a%���ύbugʱ����ͬ mtklog����Ƶһ���ύ 
pause
GOTO STARTS
:302
CLS
echo �������ʱִ��
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
echo ����wmslog�Ĳ���ִ�����
echo =============================================================
echo ������쳣��Ϣ��\wmsLogs\wmslog_%a%
echo ��������ٴθ��֣���ִ��һ�β�������ṩ�����ļ���mobile log������ץȫ������Ѿ�����ִ�й�һ�Σ����Ӵ�����
echo �ύbugʱ����Ҫ�����ύ mtklog����Ƶ���������� 
pause
GOTO STARTS



