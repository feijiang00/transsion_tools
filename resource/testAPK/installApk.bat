@echo off
rem set current_path=\\192.168.1.75\swtlog\研发一部软件测试部\自动化资源\多媒体资源\APK30  
rem cd %current_path%  
cd /d %~dp0  
rem echo %cd%
pushd %~dp0
echo %cd%
for /R %%s in (*.apk) do (  
    ::要使用引号来包括apk的路径，不然adb install语法报错  
    adb install -r "%%s"  
)  
echo 安装完成 
popd  
 