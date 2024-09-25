# 主要是查看f1比f2多出来的进程，这些进程的差距

def parse_packages(file_path):
    packages = {}
    with open(file_path) as file:
        for line in file:
            line = line.strip()
            if line:
                parts = line.split(": ", 1)
                package = parts[1].split(" (")[0]  # 去掉后面的信息
                size_str = parts[0].replace(",", "").replace("K", "")  # 去掉逗号和单位
                size = int(size_str)  # 转换为整数
                packages[package] = size
    return packages

# 解析第一个文件的包名和占用大小
file1_packages = parse_packages('f1.txt')
# 解析第二个文件的包名和占用大小
file2_packages = parse_packages('f2.txt')

# 找出 file1 中比 file2 多出的包名，并记录对应的占用大小
extra_packages = {}
for package, size in file1_packages.items():
    if package not in file2_packages:
        extra_packages[package] = size

# 根据大小进行降序排序
sorted_packages = sorted(extra_packages.items(), key=lambda x: x[1], reverse=True)

# 写入结果到文件
with open("r2.txt", "w") as file:
    for package, size in sorted_packages:
        file.write(f"{package} ({size}K)\n")