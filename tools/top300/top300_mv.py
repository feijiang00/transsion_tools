import os
import shutil
import zipfile
import subprocess
import glob
import webbrowser  # 导入 webbrowser 模块

# README 
# 运行前需要配置以下参数 参数：
# temp_dir = r'D:\tmp' 配置临时路径，自定义无所谓

# 源地址配置和目标地址配置，示例：
# source_paths = [
#     r'\\10.205.101.200\performance\Android U\X6850\vm参数修改\负\2024_03_22_16_17_13\110482539C000028\atrace\',
#     r'\\10.205.101.200\performance\Android U\X6850\vm参数修改\空\2024_03_21_11_39_23\110472539C000058\atrace\'
# ]
# destination_paths = [
#     r'E:\tmp\X6850\vm参数top300衰退\负载\',
#     r'E:\tmp\X6850\vm参数top300衰退\空载\'
# ]

# 解压trace地址配置
# batch_content = f'@echo off\n"D:\\transsion\\android_test_tool\\perfconv\\perfconv.exe" convert "{unzipped_filename}"'

# 定义后缀
suffix = '_atrace_0002_0.zip'
temp_dir = r'D:\tmp'

# 源地址和目标地址 ps:注意路径最后的\需要去掉
source_paths = [
    r'\\10.205.101.200\performance\Android U\X6850B\rc\OP-负载\119812543B000250\atrace',
    r'\\10.205.101.200\performance\Android U\X6850B\rc\空载\122672543C000029\atrace'
]
destination_paths = [
    r'E:\tmp\X6850B\【快温省】【X6850B】【beta】【PR0】【性能】负载top300总启动时长：226964 ms，对比空载：179752 ms，对比衰退26%，请分析优化\复测7%\负载',
    r'E:\tmp\X6850B\【快温省】【X6850B】【beta】【PR0】【性能】负载top300总启动时长：226964 ms，对比空载：179752 ms，对比衰退26%，请分析优化\复测7%\空载'
]

def copy_and_extract_files(filenames):
    for filename in filenames:
        for i, source_path in enumerate(source_paths):
            source_file = os.path.join(source_path, f"{filename}{suffix}")
            tmp_file = os.path.join(temp_dir, f"{filename}{suffix}")
            print(tmp_file)
            if os.path.exists(source_file):  # 检查文件是否存在
                shutil.copy(source_file, tmp_file)  # 复制文件

                with zipfile.ZipFile(tmp_file, 'r') as zip_ref:
                    zip_ref.extractall(temp_dir)

                print('解压完成')

                unzipped_filename = tmp_file.replace('.zip', '')

                batch_content = f'@echo off\n"D:\\transsion\\android_test_tool\\perfconv\\perfconv.exe" convert "{unzipped_filename}"'

                batch_file_path = os.path.join(os.getcwd(), f'convert_temp_{filename}.bat')
                with open(batch_file_path, 'w', encoding='utf-8') as batch_file:
                    batch_file.write(batch_content)

                subprocess.run([batch_file_path], shell=True)

                os.remove(batch_file_path)

                source_file = os.path.join(temp_dir, '*.html')
                html_files = glob.glob(source_file)
                shutil.move(html_files[0], destination_paths[i])
                last_filename = os.path.join(temp_dir, f"{filename}.html")

                print("移动完成")
                
                # # 使用默认的Web浏览器打开HTML文件
                # webbrowser.open(last_filename)  # 打开最后生成的 HTML 文件

if __name__ == "__main__":
    filenames = input("请输入文件名，以空格分隔：").split()
    copy_and_extract_files(filenames)
    
    # 删除 temp_dir 目录下的所有文件
    for file_name in os.listdir(temp_dir):
        file_path = os.path.join(temp_dir, file_name)
        try:
            if os.path.isfile(file_path):
                os.remove(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print(f"Error deleting {file_path}: {e}")
    
    print(f"成功删除 {temp_dir} 目录下的所有文件")