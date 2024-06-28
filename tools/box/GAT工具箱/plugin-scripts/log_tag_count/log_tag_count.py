#!/usr/bin/python
#Filename:python_test.py

import os
import time
import re
import sys
import platform

line_count = 0
tag_count = 0
time_max_h = 0
time_max_m = 0
time_max_s = 0
time_min_h = 25
time_min_m = 60
time_min_s = 60
#tag_name
tag_name_list = ['a']
tag_count_list =[0]
p = re.compile(r'^.{20}(\d+)..(\d+).(\w).(.*?):.*$')
p_2 = re.compile(r'.*\[Tag\](.*?)\[TAG\].*$')
time_p = re.compile(r'.{6}(\d+):(\d+):(\d+).*$')



file_object = open(sys.argv[1], 'r')  
path = os.path.dirname(os.path.abspath(sys.argv[1]))
#print path
file_out = open(path+"\\log_tag_count_result.txt", 'w')
lines = file_object.readlines()
for line in lines:
	line_count = line_count + 1
	match = re.match(time_p, line)
	if match:
		if (int(match.group(1)) > time_max_h or (int(match.group(1)) == time_max_h and int(match.group(2)) > time_max_m) or (int(match.group(1)) == time_max_h and int(match.group(2)) == time_max_m and int(match.group(3)) > time_max_s)):
			time_max_h = int(match.group(1))
			time_max_m = int(match.group(2))
			time_max_s = int(match.group(3))
		
		if (int(match.group(1)) < time_min_h or (int(match.group(1)) == time_min_h and int(match.group(2)) < time_min_m) or (int(match.group(1)) == time_min_h and int(match.group(2)) == time_min_m and int(match.group(3)) < time_min_s)):
			time_min_h = int(match.group(1))
			time_min_m = int(match.group(2))
			time_min_s = int(match.group(3))

	match = re.match(p_2, line)
	if match:
		if (tag_count == 0):
			tag_name_list[0] = match.group(1)
			tag_count_list[0] = 1
			tag_count = 1
		else:
			for i in range(0, tag_count):
				if (tag_name_list[i] == match.group(1)):
					tag_count_list[i] = tag_count_list[i] + 1
					break;
			else:	
				tag_name_list.append(match.group(1))				
				tag_count_list.append(1)
				tag_count = tag_count + 1
	else:
		match = re.match(p, line)
		if match:
			if (tag_count == 0):
				tag_name_list[0] = match.group(4)
				tag_count_list[0] = 1
				tag_count = 1
			else:
				for i in range(0, tag_count):
					if (tag_name_list[i] == match.group(4)):
						tag_count_list[i] = tag_count_list[i] + 1
						break;
				else:	
					tag_name_list.append(match.group(4))				
					tag_count_list.append(1)
					tag_count = tag_count + 1

print line_count
print tag_count
file_out.write("Log total count: %d, total tag count: %d\n"%(line_count,tag_count))
tag_order_list = [0]
max_count = last_max = 0

tag_order_list.append(0)
for i in range(0, tag_count):
	if tag_count_list[i] > max_count:
		max_count = tag_count_list[i]
		tag_order_list[0] = i

for i in range(1, tag_count):
	tag_order_list.append(0)
	last_max = max_count
	max_count = 0
	for m in range(0, tag_count):
		if tag_count_list[m] == last_max and m > tag_order_list[i-1]:
			tag_order_list[i] = m
			max_count = last_max
			break
		else:
			if (tag_count_list[m] > max_count and tag_count_list[m] < last_max):
				max_count = tag_count_list[m]
				tag_order_list[i] = m
print "The max time is %d:%d:%d\n"%(time_max_h, time_max_m, time_max_s)
print "The min time is %d:%d:%d\n"%(time_min_h, time_min_m, time_min_s)
time_s = (time_max_h-time_min_h)*3600 + (time_max_m-time_min_m)*60 + time_max_s - time_min_s + 1
print "In %d:%d:%d--%d:%d:%d, %d second time,Total %d count log, averge %d lines/s\n"%(time_min_h, time_min_m, time_min_s,time_max_h, time_max_m, time_max_s, time_s, line_count, line_count/time_s)

file_out.write("The max time is %d:%d:%d\n"%(time_max_h, time_max_m, time_max_s))
file_out.write("The min time is %d:%d:%d\n"%(time_min_h, time_min_m, time_min_s))	
file_out.write("In %d:%d:%d--%d:%d:%d, %d second time,Total %d count log, averge %d lines/s\n\n"%(time_min_h, time_min_m, time_min_s,time_max_h, time_max_m, time_max_s, time_s, line_count, line_count/time_s))	

for i in range(0, tag_count):
	file_out.write("The top %d tag %s log count is %d.\n"%(i+1,tag_name_list[tag_order_list[i]],tag_count_list[tag_order_list[i]]))


file_object.close()
file_out.close()

if (platform.system() == "Windows"):
	os.startfile(path)
	