#!/usr/bin/env python3

import os
import re
import subprocess
import sys
import base64

def encode(infile, outfile):
    fd = open(infile)
    try:
        buf = fd.read()
    finally:
        fd.close()

    b = bytearray(base64.b64encode(buf.encode('ascii')))
    for i in range(len(b)):
        b[i] += 33

    open(outfile, 'wb').write(b)


def decode(infile, outfile):
    b = bytearray(open(infile, 'rb').read())
    for i in range(len(b)):
        b[i] -= 33

    d = bytes.decode(base64.b64decode(b))
    open(outfile, 'w').write(d)


def usage():
    print("Usage: " + sys.argv[0] + " -e/d <input file> <output file>")

if __name__ == '__main__' :
    argc = len(sys.argv)
    if argc != 4:
        usage()
        exit()
    
    if(sys.argv[1] == "-e"):
        encode(sys.argv[2], sys.argv[3])
    elif(sys.argv[1] == "-d"):
        decode(sys.argv[2], sys.argv[3])
    else:
        usage()
        
