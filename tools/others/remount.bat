@echo off

echo "!!!!手机上打开 oem unlock: setting -> system -> Developer options -> OEM unlocking!!!!"

timeout 30
adb reboot bootloader
echo "starting fastboot, plz wait!"

fastboot oem tran_skip_confirm_key
fastboot flashing unlock
echo "processing 1/6, just a sec..."
fastboot reboot

echo "processing 2/6, just a sec..."
adb wait-for-device
adb root

echo "processing 3/6, just a sec..."
adb wait-for-device
adb disable-verity

echo "processing 4/6, just a sec..."
adb wait-for-device
adb reboot

echo "processing 5/6, just a sec..."
adb wait-for-device
adb root

echo "processing 6/6, just a sec..."
adb wait-for-device
adb remount

echo "!!!!--------------------remount done~---------------------------!!!!"

timeout 30


adb shell pm disable com.transsion.overlaysuw
adb shell settings put global device_provisioned 1
adb shell settings put secure user_setup_complete 1

timeout 30