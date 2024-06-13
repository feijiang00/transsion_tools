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
echo Step1. 开始抓取audio trace，一般用于判断卡顿类音频问题
echo       （请在完成开启log等常规操作之后，再按“任意键”，进行抓取）
pause
adb shell atrace -c -b 10240 --async_start -z rs webview dalvik freq video binder_driver view hal database wm sm audio power camera memreclaim ss res idle am input sched binder_lock bionic gfx pm android_fs disk
echo 录制中，请保持安静
echo Step2. 请现在开始复现问题1-2次
echo       （按“任意键”停止并导出到audioLogs\audiolog_%a%）
pause
adb shell atrace -c -b 10240 --async_stop -z rs webview dalvik freq video binder_driver view hal database wm sm audio power camera memreclaim ss res idle am input sched binder_lock bionic gfx pm android_fs disk > .\audiolog_%a%\T.ctrace
echo Step3. 导出audio dumplog，一般用于常规音频问题
echo       （请在完成关闭audiolog的操作后，按“任意键”，进行导出）
pause
adb root
adb remount
adb pull /data/vendor/audiohal/audio_dump/ .\audiolog_%a%\audiohal
adb pull /data/debuglogger/mobilelog .\audiolog_%a%\
adb pull /data/debuglogger/audio_dump .\audiolog_%a%\
adb pull sdcard/debuglogger/audio_dump .\audiolog_%a%\
adb shell dumpsys audio >.\audiolog_%a%\audio.txt
adb shell dumpsys media.metrics >.\audiolog_%a%\media.metrics.txt
echo Step4. 按任意键，删除手机中的Audio log
echo        (若不想删除，直接关闭即可)
pause
adb shell rm -rf data/vendor/audiohal/audio_dump/*
adb shell rm -rf data/debuglogger/audio_dump/*
adb shell rm -rf /data/vendor/audiohal/audio_dump/*
adb shell rm -rf /data/debuglogger/audio_dump/*
adb shell rm -rf sdcard/debuglogger/audio_dump/*