import subprocess
import time
import os
import sys
import webbrowser
import shutil
from datetime import datetime

class HolmesParam:
    def __init__(self, action, seriNum, bufferTime, atraceBuffer, autoStopTime, packageName, help):
        self.action = action
        self.seriNum = seriNum
        self.bufferTime = bufferTime
        self.atraceBuffer = atraceBuffer
        self.autoStopTime = autoStopTime
        self.packageName = packageName
        self.help = help

dump_tag = str(datetime.now().strftime("%Y-%#m-%d-%H%M%S"))
min_atrace_buffer = 16384
trace_dir = os.path.dirname(os.path.abspath(__file__)) + os.sep + "holmes_trace" + os.sep + dump_tag

atrace_filename = "holmes_atrace_raw.txt"
atrace_file = "/data/local/tmp/" + atrace_filename
holmes_files = []

atrace_local_file = trace_dir + os.sep + atrace_filename
holmes_local_files = []
holmes_sort_files = []
holmes_split_files = []
holmes_alignment_files = []

holmes_merge_file = trace_dir + os.sep + "holmes_trace_merged.txt"
holmes_result_file = trace_dir + os.sep + "holmes_trace.html"
systrace_header = ("# tracer: nop \n#\n# entries-in-buffer/entries-written: 1/1   #P:8\n#\n#                                          _-----=> irqs-off\n#                                         / _----=> need-resched\n#                                        | / _---=> hardirq/softirq\n#                                        || / _--=> preempt-depth\n#                                        ||| /     delay\n#           TASK-PID       TGID    CPU#  ||||   TIMESTAMP  FUNCTION\n#              | |           |       |   ||||      |         |\n")

def parseHolmesParams():
    action = ""
    seriNum = ""
    bufferTime = "10"
    autoStopTime = 0
    packageName = ""
    atraceBuffer = 65536
    help = False
    for i in range(1, len(sys.argv)):
        param = sys.argv[i]
        if param == "--auto_dump":
            autoStopTime = float(sys.argv[i + 1])
            if autoStopTime == 0:
                raise Exception("auto dump param error")
        elif param == "--buffer_time":
            bufferTime = int(sys.argv[i + 1])
            if bufferTime == 0:
                raise Exception("buffer time param error")
        elif param == "--seriNum":
            seriNum = sys.argv[i + 1]
            if len(seriNum) == 0:
                raise Exception("seriNum param error")
        elif param == "--packages":
            tmpPakcageName = sys.argv[i + 1]
            if len(tmpPakcageName) == 0:
                raise Exception("pakcageName param is null")
            packages = tmpPakcageName.split(",")
            packageName = " ".join(i for i in packages)
        elif param == "--help":
            help = True
        elif param == "--action":
            action = sys.argv[i + 1]
            if action != "start" and action != "stop" and action != "dump":
                raise Exception("action param error (start, stop, dump)")
        elif param == "--atrace_buffer":
            buffer = int(sys.argv[i + 1])
            if buffer < min_atrace_buffer:
                buffer = min_atrace_buffer
            atraceBuffer = buffer

    return HolmesParam(action, seriNum, str(bufferTime), str(atraceBuffer), autoStopTime, packageName, help)


def showHelp():
    print("Holmes usage:")
    print("--action [start,stop,dump][must] ")
    print("--packages [name][must]: Package or PID for target applications, Use ',' to separate")
    print("--auto_dump [time][option]: After X seconds, it dumps automatically")
    print("--seriNum [num][option]: If you want to capture the serial number of the device you want to capture, you can ignored it If only one device is connected")
    print("--buffer_time [time][option]: Default 10s, Holmes trace duration, affect the size of the buffer")
    print("--atrace_buffer [time][option]: systrace buffer size, default 65536KB, the smallest " + str(min_atrace_buffer) + "KB")

def main():
    params = parseHolmesParams()
    if params.help == True:
        showHelp()
        return
    
    print("Target packages: " + params.packageName)

    realSeriNum = checkDeviceExists(params.seriNum)
    if realSeriNum.strip() is '':
        return
    print("[Pass] The device exists: " + realSeriNum)

    if params.action == "start":
        if startTrace(realSeriNum, params) == False:
            print("start tracef failed")
            return
        print(params.autoStopTime)
        
        if params.autoStopTime != 0:
            print("sleeping " + str(params.autoStopTime) + " seconds for capture trace")
            time.sleep(params.autoStopTime)
            dumpTrace(realSeriNum, params)
    elif params.action == "dump":
        dumpTrace(realSeriNum, params)
    elif params.action == "stop":
        stopTrace(realSeriNum, params)

        
def stopTrace(realSeriNum, params):
    print("\n\nStop atrace and holmes trace")
    stopAtrace(realSeriNum)
    stopHolmesTrace(realSeriNum, params.packageName)
    clearTmpFile(realSeriNum)

def dumpTrace(realSeriNum, params):
    # need clear tmp file
    holmesDumpResult = dumpHolmesTrace(realSeriNum, params.packageName)

    print("\nsleeping 2 seconds for holmes")
    time.sleep(2)

    atrceResult = dumpAtrace(realSeriNum)
    holmesResut = doHolmesResult(holmesDumpResult)
    if atrceResult == False or holmesResut == False:
        clearTmpFile(realSeriNum)
        return
    
    fileReuslt = prepareTraceFiles(realSeriNum)
    clearTmpFile(realSeriNum)

    if fileReuslt == 0:
        return
    
    # try split file
    splitHolmesFiles()

    # try sort all holmes files
    sortHolmesFiles()
    
    if alignmentHolmesTrace() == False:
        return
    
    mergeHolmesTrace()
    mergeAllTrace()
    openFile(holmes_result_file)

def startTrace(realSeriNum, params):
    captureResult = captureAtrace(realSeriNum, params.atraceBuffer)
    if captureResult is False:
        return False
    
    captureHolmesResult = captureHolmesTrace(realSeriNum, params.bufferTime, params.packageName)
    if captureHolmesResult is False:
        stopAtrace(realSeriNum) 
        return False
    return True

def openFile(file):
    webbrowser.open_new_tab("https://ui.perfetto.dev/")
    try:
        import pyautogui
    except ImportError:
        print("Can not open file auto, please run pip install pyautogui")
        return
    pyautogui.write(file)

def mergeAllTrace():
    print("\n\n12. Try merge holmes and atrace...")
    files = [holmes_merge_file, atrace_local_file]
    mergeTraceFiles(files, holmes_result_file, systrace_header)


def mergeHolmesTrace():
    print("\n\n11. Try merge holmes trace: " + str(holmes_alignment_files))
    if len(holmes_alignment_files) > 1:
        mergeTraceFiles(holmes_alignment_files, holmes_merge_file, "")
    else:
        shutil.copyfile(holmes_alignment_files[0], holmes_merge_file)


def mergeTraceFiles(files, targetFile, header):
    mark_line = ("# tracer: nop\n")
    handles = []
    lines = []
    for file in files:
        handle = open(file, "r")
        line = handle.readline()

        # filter mark_line
        while line.find(mark_line) == -1:
            line = handle.readline()

        # filter #line
        while line.startswith("#"):
            line = handle.readline()
        if line != "":
            handles.append(handle)
            lines.append(line)
        else:
            handle.close()

    print("write files to target file")
    with open(targetFile, "w") as mf:
        if len(header) != 0:
            mf.writelines(header)
        else:
            mf.writelines(mark_line)
        while len(lines) != 0:
            writeLine = findWriteLine(handles, lines)
            mf.writelines(writeLine)
        mf.close()

def alignmentHolmesTrace():
    print("\n\n10. Try alignment holmes trace: " + str(holmes_sort_files))
    if os.path.exists(atrace_local_file) == False:
        print("Error: atrace not found")
        return False
    diffTime = getDiffTime(atrace_local_file)
    if diffTime == 0:
        print("Erro: atrace can not find diffTime")
        return False
    for i in range(len(holmes_sort_files)):
        alignmentTrace(holmes_sort_files[i], holmes_alignment_files[i], diffTime)
        print(holmes_sort_files[i])

    return True

def splitHolmesFiles():
    print("\n\n8. Try split holmes local files: " + str(holmes_local_files))
    for i in range(len(holmes_local_files)):
        files = splitTrace(holmes_local_files[i], holmes_local_files[i][0:-4])
        for splitFile in files:
            holmes_split_files.append(splitFile)
            holmes_sort_files.append(splitFile[0:-4] + "_sort.txt")
            holmes_alignment_files.append(splitFile[0:-4] + "_alig.txt")
            print(splitFile)


def sortHolmesFiles():
    print("\n\n9. Try sort holmes split files: " + str(holmes_split_files))

    for i in range(len(holmes_split_files)):
        sortTrace(holmes_split_files[i], holmes_sort_files[i])
        print(holmes_sort_files[i])


def prepareTraceFiles(seriNum):
    print("\n\n7. Try prepare trace files to dir:" + dump_tag)
    print(trace_dir)
    try:
        os.makedirs(trace_dir)
    except Exception as e:
        print("mkdirs failed:" + trace_dir)
        print(e)
        return 0
    count = 0
    cmdResult = execute("adb -s " + seriNum + " pull " + atrace_file + " " + trace_dir)
    if (cmdResult.find("1 file pulled") != -1):
        count = count + 1
        print(cmdResult)
    else:
        print("pull file failed: " + atrace_file)
    for holmesFile in holmes_files:
        cmdResult = execute("adb -s " + seriNum + " pull " + holmesFile + " " + trace_dir)
        if (cmdResult.find("1 file pulled") != -1):
            count = count + 1
            holmes_local_path = trace_dir + os.sep + holmesFile.split("/")[-1]
            holmes_local_files.append(holmes_local_path)
            print(cmdResult)
        else:
            print("pull file failed: " + holmesFile)
    if count == 0:
        print("Error: 0 trace files")
    return count

def doHolmesResult(res):
    print("\n\n6. Try get holmes files...")
    result = waitResult(res)
    lines = result.splitlines()
    tag = "File: "
    for subline in lines:
        if (subline.startswith(tag)):
            holmes_files.append(subline[len(tag):])
    print("holmes files:" + str(holmes_files))
    return lines[-1] == "Waiting for method dump to finish..."

def dumpAtrace(seriNum):
    print("\n\n5. Try dump atrace...")

    command = "adb -s " + seriNum + " shell atrace --async_stop -o " + atrace_file
    print("Command: " + command)

    result = execute(command)
    
    if result.strip() == "done":
        print("Dump trace done!")
        return True
    else:
        print("Error: Dump atrace failed: " + result)
        return False

def dumpHolmesTrace(seriNum, packageName):
    print("\n\n4. Try dump holmes trace...")
    command = "adb -s " + seriNum + " shell am method-trace -c dump " + packageName
    print("Command: " + command)
    return executeNoWait(command)

def captureHolmesTrace(seriNum, duration, packageName):
    print("\n\n3. Try capture holmes trace...")
    command = "adb -s " + seriNum + " shell am method-trace -c start -t " + duration + " " + packageName
    print("Command: " + command)

    result = execute(command)

    if len(result) == 0:
        print("Capturing holmes trace...........")
        return True
    else:
        print("Error: Capture holmes failed: " + result)
        stopHolmesTrace(seriNum, packageName)
        return False

def stopHolmesTrace(seriNum, packageName):
    print("Clear: stop holmes")
    command = "adb -s " + seriNum + " shell am methd-trace -c stop " + packageName
    executeNoWait(command).stdout.close()

def stopAtrace(seriNum):
    print("Clear: stop atrace")
    command = "adb -s " + seriNum + " shell atrace --async_stop"
    executeNoWait(command).stdout.close()

def captureAtrace(seriNum, bufferSize):
    print("\n\n2. Try capture atrace...")
    atrace_capture_command = "atrace --async_start -b " + bufferSize + " gfx input view webview wm am camera dalvik bionic pm database sched irq freq idle disk sync binder_driver"

    command = "adb -s " + seriNum + " shell " + atrace_capture_command
    print("Command: " + command)

    result = execute(command)

    print("Capture atrace result: " + result)
    if result.startswith("capturing trace"):
        print("Capturing atrace...........")
        return True
    else:
        print("Error: Capture atrace failed: " + result)
        return False
        

def checkDeviceExists(seriNum):
    print("\n\n1. Check device exists...")
    devices = execute("adb devices")
    if devices.startswith("List of devices attached") == False:
        print("Error: " + devices)
        return False
    lines = devices.splitlines()
    
    foundSeriNum = ''
    for line in lines:
        sublines = line.split("\t")
        if len(sublines) == 2:
            if sublines[1] == "device":
                if seriNum is None or seriNum.strip() == '':
                    if foundSeriNum.strip() is not '':
                        print("Error: Connect too many devices and need to specify a serial number")
                        return ''
                    foundSeriNum = sublines[0]
                    
                elif sublines[0] == seriNum:
                    if foundSeriNum.strip() is not '':
                        print("Error: The same serial number for both devices? No way!")
                        return ''
                    foundSeriNum = seriNum
                    
    return foundSeriNum.strip()

def execute(cmd):
    res = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result = res.stdout.read()
    res.wait()
    res.stdout.close()
    return result

def executeNoWait(cmd):
    return subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def waitResult(res):
    result = res.stdout.read()
    res.wait()
    res.stdout.close()
    return result

def clearTmpFile(seriNum):
    execute("adb -s " + seriNum + " shell rm " + atrace_file)
    for holmesFile in holmes_files:
        execute("adb -s " + seriNum + " shell rm " + holmesFile)           

def splitTrace(org_file, prefix_file):
    lineCount = 0
    loopCount = 0
    maxSplitCount = 256 * 10000
    lines = []

    splitFiles = []
    
    with open(org_file, "r") as f:
        for line in f:
            lineCount += 1
            lines.append(line)
            if lineCount == maxSplitCount:
                splitFile = prefix_file + "_" + str(loopCount) + ".txt"
                handle = open(splitFile, "w")
                handle.writelines(lines)
                handle.close()
                splitFiles.append(splitFile)
                loopCount += 1
                lineCount = 0
                del lines[:]
        if lineCount > 0:
            if loopCount > 0:
                splitFile = prefix_file + "_" + str(loopCount) + ".txt"
                handle = open(splitFile, "w")
                handle.writelines(lines)
                handle.close()
                splitFiles.append(splitFile)
                del lines[:]
            else:
                splitFiles.append(org_file)
        f.close()
    return splitFiles

def sortTrace(org_file, sort_file):
    lines_dic = {}
    header = ("# tracer: nop\n")
    with open(org_file, "r") as f:
        for line in f:
            if line.startswith('#'):
                header += line
                continue
            if "<...>-1" in line:
                continue
            newline = ("")
            items = line.split(" [00")
            if len(items) < 2:
                continue
            time = float(items[1].split()[2][:-1])
            if lines_dic.has_key(time):
                old = lines_dic[time]
                newline = old + line
            else:
                newline = line
            lines_dic[time] = newline
        f.close()
    with open(sort_file, "w") as sf:
        sf.writelines(header)
        for i in sorted(lines_dic):
            sf.writelines(lines_dic[i])
        sf.close()

def alignmentTrace(sorted_file, alignment_file, diffTime):
    af_handle = open(alignment_file, "w")
    with open(sorted_file, "r") as f:
        for line in f:
            if (line.startswith('#')):
                af_handle.writelines(line)
            else:
                items = line.split(" [00")
                if len(items) < 2:
                    continue
                time = float(items[1].split()[2][:-1])
                newTime = '%.6f'% (time + diffTime)
                newLine = line.replace(str(time), str(newTime))
                af_handle.writelines(newLine)
    af_handle.close()       
            
def findWriteLine(handles, lines):
    writeLine = ""
    minTime = float(sys.maxsize)
    minIndex = 0
    for line in lines:
        lineTime = getTime(line)
        if lineTime < minTime:
            minTime = lineTime
            writeLine = line
            minIndex = lines.index(line)
    lines.remove(writeLine)

    handle = handles[minIndex]
    nextLine = handle.readline()
    if len(nextLine) == 0:
        handles.remove(handle)
        handle.close()
    else:
        lines.insert(minIndex, nextLine)

    return writeLine
    
def mergeTrace(alignment_file, systrace_file, merged_file):
    mark_line = ("# tracer: nop")
    
    sf_handle = open(alignment_file, "r")
    sf_line = sf_handle.readline()
    while sf_line.find(mark_line) == -1:
        sf_line = sf_handle.readline()

    while sf_line.startswith("#"):
        sf_line = sf_handle.readline()

    tf_handle = open(systrace_file, "r")
    tf_line = tf_handle.readline()

    while tf_line.find(mark_line) == -1:
        tf_line = tf_handle.readline()

    while tf_handle.readline().startswith("#"):
        tf_line = tf_handle.readline()

    if tf_line == "" and sf_line == "":
        print("file exception")
        tf_handle.close()
        sf_handle.close()
        return
    

    with open(merged_file, "w") as mf:
        #mf.writelines(header)
        while tf_line != "" or sf_line != "":
            if tf_line != "" and sf_line != "":
                tf_time = getTime(tf_line)
                sf_time = getTime(sf_line)
                if tf_time <= sf_time:
                    mf.writelines(tf_line)
                    tf_line = getNextLine(tf_handle)
                else:
                    mf.writelines(sf_line)
                    sf_line = getNextLine(sf_handle)
            else:
                if tf_line != "":
                    mf.writelines(tf_line)
                    tf_line = getNextLine(tf_handle)
                else:
                    mf.writelines(sf_line)
                    sf_line = getNextLine(sf_handle)
        mf.close()

    tf_handle.close()
    sf_handle.close()


def getNextLine(handle):
    line = handle.readline()
    stripLine = line.strip()
    while stripLine.startswith("</") or stripLine.startswith("<!"):
        line = handle.readline()
        stripLine = line.strip()
    return line

def getTime(line):
    items = line.split(" [00")
    if len(items) < 2:
        return -1
    time = float(items[1].split()[2][:-1])
    return time

def getDiffTime(systrace_file):
    end_time_tag = "holmes_trace_end"
    second_end_time_tag = "holmes_trace_end_second"
    minDiffTime = -float(sys.maxsize)
    lastSystraceTime = 0
    sys_handle = open(systrace_file, "r")
    sys_line = sys_handle.readline()
    while len(sys_line) != 0:
        if sys_line.find(second_end_time_tag) != -1:
            print(sys_line)
            if lastSystraceTime == 0:
                print("Error: unreachable!!!")
                sys_line = sys_handle.readline()
                continue
            curSystraceTime = getTime(sys_line)
            if curSystraceTime - lastSystraceTime > 0.003:
                print("Error: the time interval between the two gaps is too long!!!")
                lastSystraceTime = 0
                sys_line = sys_handle.readline()
                continue
            holmesTime = float(sys_line.split("=")[-1])
            diffTime = lastSystraceTime - holmesTime
            print("diffTime: " + str(diffTime))
            if abs(minDiffTime) > abs(diffTime):
                minDiffTime = diffTime
                print
            lastSystraceTime = 0
        elif sys_line.find(end_time_tag) != -1:
            lastSystraceTime = getTime(sys_line)
            print(sys_line)
        sys_line = sys_handle.readline()

    sys_handle.close()
    print("minDiffTime: " + str(minDiffTime))
    return minDiffTime


if __name__ == "__main__":
    main()

