#!/bin/bash

# 定义Facebook应用的包名
PACKAGE_NAME="com.facebook.katana"

# 停止Facebook应用
adb shell am force-stop $PACKAGE_NAME

# 等待300毫秒
sleep 0.3

# 启动Facebook应用
adb shell monkey -p $PACKAGE_NAME -c android.intent.category.LAUNCHER 1

# 等待300毫秒
sleep 0.3

# 在Facebook的主页面上模拟滑动操作
# 注意：下面的坐标可能需要根据你的设备屏幕分辨率进行调整
adb shell input swipe 300 1000 300 500 200
