#!/bin/bash

# 获取参数
LOG_DIR="$1"
TARGET_TIME="$2"
TIME_RANGE="$3"

echo "====================输入的时间点是:$TARGET_TIME===================="
# 检查是否传入了第三个参数
if [ -z "$3" ]; then

  # 可以在这里设置一个默认值或者进行其他处理
  TIME_RANGE="1"
else
  TIME_RANGE="$3"
fi

# 目标时间转换为秒
TARGET_SECONDS=$(date -d "1970-01-01 $TARGET_TIME UTC" +%s)

# 定义一个函数来过滤和输出标准时间戳日志
filter_logs() {
  local keyword1="$1"
  local negate1="$2"
  local keyword2="$3"
  local negate2="$4"
  local label="$5"
  local before_lines="$6"
  local after_line="$7"
  local range_multiplier="$8"
  
  echo -e "\n==================== $label 分割线 ===================="

  # 构建第一个 grep 命令
  if [ "$negate1" == "true" ]; then
    grep_cmd1="grep --binary-files=text -v \"$keyword1\""
  else
    grep_cmd1="grep --binary-files=text \"$keyword1\""
  fi

  # 检查是否传入第二个关键字和其取反参数
  if [ -n "$keyword2" ]; then
    if [ "$negate2" == "true" ]; then
      grep_cmd2="grep --binary-files=text -v \"$keyword2\""
    else
      grep_cmd2="grep --binary-files=text \"$keyword2\""
    fi
  else
    grep_cmd2="cat"  # 如果没有传入第二个关键字，直接传递所有行
  fi

  # 运行组合后的 grep 命令
  eval "grep -rni --binary-files=text -A \"$after_line\" -B \"$before_lines\" \"$LOG_DIR\" | $grep_cmd1 | $grep_cmd2" | while read -r line; do
    # 调试 打印line 
    # echo "$line"

    # 提取标准时间戳部分 (例如 22:36:01.436184)
    TIMESTAMP=$(echo "$line" | grep -oP '\d{2}:\d{2}:\d{2}\.\d{3,6}' | cut -d'.' -f1)

    if [ -n "$TIMESTAMP" ]; then
      # 当前行时间转换为秒
      LOG_SECONDS=$(date -d "1970-01-01 $TIMESTAMP UTC" +%s)
     
      # 计算时间差
      TIME_DIFF=$((LOG_SECONDS - TARGET_SECONDS))
      ABS_TIME_DIFF=${TIME_DIFF#-}

      # 检查是否在时间范围内，乘以范围倍数
      if [ "$ABS_TIME_DIFF" -le $((TIME_RANGE * range_multiplier)) ]; then
        echo "$line"
      fi
    fi
  done
}

# 参数含义： 过滤关键字1 是否反向过滤1 过滤关键字2(可选) 是否反向过滤2(可选) 标题 向前多少行 向后多少行 倍数范围

# 过滤anr日志
filter_logs "am_anr" false "" "" "ANR" 0 0 10

# 过滤crash 日志
filter_logs "am_crash" false "" "" "crash" 0 0 10

# 过滤 am_proc_start 日志
filter_logs "am_proc_start" false "next-top-activity" true "应用自启" 0 0 10

# 过滤 am_proc_start 日志(用户收到启动)
filter_logs "am_proc_start" false "next-top-activity" false "用户手起" 0 0 10

# 过滤 lowmemorykiller: Kill 日志
filter_logs "lowmemorykiller: Kill" false "" "" "低内存查杀" 0 0 10

# 过滤 SKIN 日志
filter_logs "SKIN" false "" "" "板温" 0 0 2

# 过滤 thermal_core 日志
filter_logs "thermal_core" false "" "" "限频" 0 0 10



# 定义一个函数来输出内存信息
output_meminfo() {
  echo -e "\n==================== meminfo 分割线 ===================="
  # 找到包含 meminfo 的文件
  find "$LOG_DIR" -type f -name "*meminfo*" | while read -r file; do
    # 在文件中查找 Total RAM: 并输出其后面10行
    grep -A 10 "Total RAM:" "$file"
  done
}

# 输出内存信息
output_meminfo

filter_tran_perf_logs() {
  echo -e "\n==================== cpu loading 分割线 ===================="
  local target_time="$1"
  local time_range="$2"
  local log_dir="$3"

  # 提取 TRAN Perf 日志行中的时间戳
  grep "TRAN Perf" "$log_dir" -rni --include="*kernel*" | grep -oP '\(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\)' | grep -oP '\d{2}:\d{2}:\d{2}' | while read -r timestamp; do
    # 当前行时间转换为秒
    log_seconds=$(date -d "1970-01-01 $timestamp UTC" +%s)
    time_diff=$((log_seconds - TARGET_SECONDS))
    abs_time_diff=${time_diff#-}

    # 检查是否在时间范围内，前后50s
    if [ "$abs_time_diff" -le $((time_range * 50)) ]; then
      echo "$timestamp"
    fi
  done | sort -u | head -n $((time_range * 10)) > /tmp/filtered_times.txt #取10个

  # 继续筛选并输出前后7行
  grep "TRAN Perf" "$log_dir" -rni --include="*kernel*" | while read -r line; do
    for time in $(cat /tmp/filtered_times.txt); do
      if echo "$line" | grep -q "$time"; then
        # 提取文件名和行号
        file=$(echo "$line" | cut -d: -f1)
        line_num=$(echo "$line" | cut -d: -f2)

        # 输出匹配行及其后的7行
        sed -n "${line_num},$((line_num + 8))p" "$file"
      fi
    done
  done
}

# 调用新功能
filter_tran_perf_logs "$TARGET_TIME" "$TIME_RANGE" "$LOG_DIR"
