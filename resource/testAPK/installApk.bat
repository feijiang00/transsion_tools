@echo off
rem set current_path=\\192.168.1.75\swtlog\�з�һ��������Բ�\�Զ�����Դ\��ý����Դ\APK30  
rem cd %current_path%  
cd /d %~dp0  
rem echo %cd%
pushd %~dp0
echo %cd%
for /R %%s in (*.apk) do (  
    ::Ҫʹ������������apk��·������Ȼadb install�﷨����  
    adb install -r "%%s"  
)  
echo ��װ��� 
popd  
 