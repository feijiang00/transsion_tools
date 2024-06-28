# 获取当前手机mfoucs的应用的pid

import subprocess
import re

def get_focused_app():
    try:
        # 获取当前聚焦的应用信息
        result = subprocess.check_output(['adb', 'shell', 'dumpsys', 'activity'], encoding='utf-8')
        for line in result.splitlines():
            if 'mFocusedApp' in line:
                # 使用正则表达式提取包名
                match = re.search(r'mFocusedApp=.*? ([^/]+)/', line)
                if match:
                    return match.group(1)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
    except UnicodeDecodeError as e:
        print(f"Unicode decode error: {e}")
    return None

def get_pid(app_package):
    try:
        # 获取应用的PID
        result = subprocess.check_output(['adb', 'shell', 'pidof', app_package], encoding='utf-8')
        return result.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
    except UnicodeDecodeError as e:
        print(f"Unicode decode error: {e}")
    return None

if __name__ == "__main__":
    app_package = get_focused_app()
    if app_package:
        pid = get_pid(app_package)
        if pid:
            print(pid)  # 只打印PID，便于批处理脚本捕获
        else:
            print("Could not find PID for the app: {app_package}")
    else:
        print("Could not find the focused app")
