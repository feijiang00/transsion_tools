@echo off
adb wait-for-device
adb root
adb shell rm -rf data/vendor/audiohal/audio_dump/*
adb shell rm -rf data/debuglogger/audio_dump/*
adb shell rm -rf /data/vendor/audiohal/audio_dump/*
adb shell rm -rf /data/debuglogger/audio_dump/*
adb shell rm -rf sdcard/debuglogger/audio_dump/*
set a=%Date:~0,4%%date:~5,2%%date:~8,2%%hm%_%Time:~0,2%_%Time:~3,2%_%Time:~6,2%
md .\audiolog_%a%
echo Step1. ��ʼץȡaudio trace��һ�������жϿ�������Ƶ����
echo       ��������ɿ���log�ȳ������֮���ٰ����������������ץȡ��
pause
adb shell atrace -c -b 10240 --async_start -z rs webview dalvik freq video binder_driver view hal database wm sm audio power camera memreclaim ss res idle am input sched binder_lock bionic gfx pm android_fs disk
echo ¼���У��뱣�ְ���
echo Step2. �����ڿ�ʼ��������1-2��
echo       �������������ֹͣ��������audioLogs\audiolog_%a%��
pause
adb shell atrace -c -b 10240 --async_stop -z rs webview dalvik freq video binder_driver view hal database wm sm audio power camera memreclaim ss res idle am input sched binder_lock bionic gfx pm android_fs disk > .\audiolog_%a%\T.ctrace
echo Step3. ����audio dumplog��һ�����ڳ�����Ƶ����
echo       ��������ɹر�audiolog�Ĳ����󣬰���������������е�����
pause
adb root
adb remount
adb pull /data/vendor/audiohal/audio_dump/ .\audiolog_%a%\audiohal
adb pull /data/debuglogger/mobilelog .\audiolog_%a%\
adb pull /data/debuglogger/audio_dump .\audiolog_%a%\
adb pull sdcard/debuglogger/audio_dump .\audiolog_%a%\
adb shell dumpsys audio >.\audiolog_%a%\audio.txt
adb shell dumpsys media.metrics >.\audiolog_%a%\media.metrics.txt
echo Step4. ���������ɾ���ֻ��е�Audio log
echo        (������ɾ����ֱ�ӹرռ���)
pause
adb shell rm -rf data/vendor/audiohal/audio_dump/*
adb shell rm -rf data/debuglogger/audio_dump/*
adb shell rm -rf /data/vendor/audiohal/audio_dump/*
adb shell rm -rf /data/debuglogger/audio_dump/*
adb shell rm -rf sdcard/debuglogger/audio_dump/*