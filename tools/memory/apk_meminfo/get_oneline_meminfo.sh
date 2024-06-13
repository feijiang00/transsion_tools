# 运行说明：shell环境下，带入参数：例如./get_oneline_meminfo.sh "TOTAL PSS"
# 统计文件中每一行的搜索到的key，的第三个字段
#            TOTAL PSS:   406003            TOTAL RSS:   591052       TOTAL SWAP PSS:     1597
# 比如这里，输出406003

# 文件中修改的参数，echo "x6850"：格式头；{print $3}：打印n字段；x6850_meminfo.txt：匹配文件名
#!/bin/bash
keyword=$1

if [ -z "$keyword" ]; then
  echo "Usage: $0 <keyword>"
  exit 1
fi

paste <(echo "AE10"; awk -v keyword="$keyword" '$0 ~ keyword {print $3}' AE10_meminfo.txt) \
     <(echo "AD10"; awk -v keyword="$keyword" '$0 ~ keyword {print $3}' AD10_meminfo.txt) \
    # <(echo "x6850_vm"; awk -v keyword="$keyword" '$0 ~ keyword {print $3}' x6850_vm_meminfo.txt)