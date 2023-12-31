#!/usr/local/bin/python3
# coding: utf-8

import sys
from pathlib import Path
import re
import os

spacedir = sys.argv[1]
larkdir = sys.argv[2]
addLookin = sys.argv[3]

podpaths = list(Path(spacedir).glob('**/*.podspec'))

# 将 podfile 读取到内存中
with open(f'{larkdir}/Podfile', 'r') as f:
	lines = f.readlines()
# 写的方式打开 podfile
lineCount = len(lines)
with open(f'{larkdir}/Podfile', 'w') as f:
	for lineIndex in range(lineCount):
		for podpath in podpaths:
			name = podpath.stem
			line = lines[lineIndex]
			matchObj = re.search( rf"pod '({name}(/.*?)?)'", line)
			if matchObj:
				podName = matchObj.group(1)
				path = str(podpath.parent)
				print('修改前：', line)
				line = f"  pod '{podName}', :path => '{path}'\n"
				print('改完后：', line)
				lines[lineIndex] = line
	f.writelines(lines)

# 将 if_pod.rb 读取到内存中
with open(f'{larkdir}/if_pod.rb', 'r') as f:
	lines = f.readlines()
# 写的方式打开 if_pod.rb
lineCount = len(lines)
with open(f'{larkdir}/if_pod.rb', 'w') as f:
	for lineIndex in range(lineCount):
		for podpath in podpaths:
			name = podpath.stem
			line = lines[lineIndex]
			matchObj = re.search( rf"pod '({name}(/.*?)?)'", line)
			if matchObj:
				podName = matchObj.group(1)
				path = str(podpath.parent)
				print('修改前：', line)
				line = f"      if_pod '{podName}', :path => '{path}'\n"
				print('改完后：', line)
				lines[lineIndex] = line
	f.writelines(lines)

if addLookin == "true":
	os.system("python3 ./Scripts/addLookinToLark.py %s" % (larkdir))