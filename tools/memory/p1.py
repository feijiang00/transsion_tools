# 统计两份meminfo文件中的process的内存差异，f1减去f2中的进程所占内存，也就是看下f1中的内存到底比f2中高在哪

def parse_size(size):
    size = size.replace(',', '')  # 去除逗号
    return int(size[:-1])  # 去除 'K' 并转为整数

def parse_package(package):
    package = package.split(" ")[0]  # 只取第一个空格之前的部分
    return package

def parse_file(file_path):
    data = {}
    with open(file_path) as file:
        for line in file:
            line = line.strip()
            if line:
                size, full_package = line.split(": ")
                package = parse_package(full_package)  # 解析包名
                data[package] = parse_size(size)  # 解析大小并存储在字典中
    return data

# 解析第一个文件
file1_data = parse_file('f1.txt')
# 解析第二个文件
file2_data = parse_file('f2.txt')

# 计算大小的差异
diff_data = {}
for package in file1_data:
    if package in file2_data:
        diff = file1_data[package] - file2_data[package]
        diff_data[package] = diff
    else:
        diff_data[package] = file1_data[package]

# 按大小排序
sorted_diff_data = dict(sorted(diff_data.items(), key=lambda x: x[1], reverse=True))

# 写入结果到文件
with open("result.txt", "w") as file:
    for package, diff in sorted_diff_data.items():
        line = "size: {:,}K, process: {}\n".format(diff, package)
        file.write(line)