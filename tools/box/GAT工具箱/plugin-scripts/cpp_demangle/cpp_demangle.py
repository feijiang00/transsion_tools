'''
Created on 2016-05-24
@author: mtk80143                  
'''
import sys
import os
import time
import platform
import sys
import re
import inspect
import subprocess

gDebug = False

def cpp_functions_demangle(inputfile, outputfile):
    first_line = 1
    need_demangle = 0

    demangle_file_path = inspect.getfile(inspect.currentframe())
    if gDebug: print "platform:%s"%sys.platform
    if sys.platform.startswith("win"):
        cppfilt = os.path.join(os.path.abspath(os.path.dirname(demangle_file_path)), "demangle_tools/arm-linux-androideabi-c++filt.exe")
    else:
        cppfilt = os.path.join(os.path.abspath(os.path.dirname(demangle_file_path)), "demangle_tools/arm-linux-androideabi-c++filt")
    if gDebug: print "demangle_file:%s\ncppfilt_tool:%s"%(demangle_file_path, cppfilt)

    f_in = open(inputfile, "r")
    data_raw = f_in.read()
    f_in.close();
    data_demangle = ""

    cpp_func_kwd = '(_Z'
    cpp_func_end_kwd = '+'
    cpp_func_start = -1
    cpp_func_end = -1

    for ln in data_raw.split("\n"):
        if first_line == 1:
            first_line = 0
        else:
            data_demangle += '\n'

        if cpp_func_kwd in ln:
            if gDebug: print "line:%s"%ln
            cpp_func_start = ln.find(cpp_func_kwd)+1
            cpp_func_end = ln.find(cpp_func_end_kwd, cpp_func_start)
            if cpp_func_end == -1:
                data_demangle += ln
                continue

            # find cpp mangle fucntion
            function_raw = ln[cpp_func_start:cpp_func_end]
            if gDebug: print "function_raw:%s"%function_raw

            function_demangle = subprocess.check_output([cppfilt, function_raw]).strip('\r\n')
            if gDebug:  print "function_demangle:%s"%function_demangle
            ln_demangle = ln.replace(function_raw, function_demangle)
            if gDebug: print "line_demangle:%s"%ln_demangle
            data_demangle += ln_demangle
            if need_demangle == 0:
                need_demangle = 1
        else:
            data_demangle += ln

    if need_demangle == 1:
        f_out = open(outputfile, "w")
        f_out.write(data_demangle)        
        f_out.close()
    else:
        print "!!! No cpp functions need demangle"


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print "Usage: \npython cpp_demangle.py input_file output_file"
        exit(1)

    print "input file:%s\noutput file:%s"%(sys.argv[1], sys.argv[2])
    cpp_functions_demangle(sys.argv[1], sys.argv[2])
