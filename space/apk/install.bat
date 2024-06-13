@echo off
setlocal enabledelayedexpansion

REM 获取当前目录
set "current_dir=%cd%"

REM 遍历当前目录下所有apk文件
for %%f in ("%current_dir%\*.apk") do (
    REM 安装apk文件
    adb install "%%f"
)