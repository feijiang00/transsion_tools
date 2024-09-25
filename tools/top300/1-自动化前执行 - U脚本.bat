@echo off
for /f "tokens=1" %%a in ('adb devices ^| findstr /R /V "List devices$"') do (
    echo Uninstalling apps on device: %%a
    adb -s %%a uninstall za.co.fnb.connect.itt
    adb -s %%a uninstall africa.finserve.mkey
    adb -s %%a uninstall com.rahazachumbani.app
    adb -s %%a uninstall com.shopclues
    adb -s %%a uninstall com.asiainno.uplive
    adb -s %%a uninstall video.like
    adb -s %%a uninstall com.ludashi.dualspace
    adb -s %%a uninstall com.cyberlink.youperfect
    adb -s %%a uninstall com.callerscreen.color.phone.ringtone.flash
    adb -s %%a uninstall com.adobe.lrmobile
    adb -s %%a uninstall com.jio.media.ondemand
    adb -s %%a uninstall com.sharekaro.app
    adb -s %%a uninstall id.dana
    adb -s %%a uninstall share.sharekaro.pro
    adb -s %%a uninstall vpn.video.downloader
    adb -s %%a shell settings put system screen_off_timeout 1800000
    echo Done with device: %%a
)

pause
