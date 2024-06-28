@rem don't modify the caller's environment
@setlocal

@rem Change current directory and drive to where the script is, to avoid
@rem issues with directories containing whitespaces.
@cd /d %~dp0

@cd ..\..\modules
@..\prebuilt\python\bin\python2.7.exe ..\plugin-scripts\bugreport\mtkbugreport_shell.pyc