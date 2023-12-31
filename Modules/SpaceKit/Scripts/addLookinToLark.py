#!/usr/local/bin/python3
# coding: utf-8

import sys
from pathlib import Path
import re

def indexOf(pattern, filePath):
    with open(filePath, 'r') as f:
        lines = f.readlines()
        lineCount = len(lines)
        for lineIndex in range(lineCount):
            line = lines[lineIndex]
            match = re.search(pattern, line)
            if match:
                return lineIndex
    return -1

def insert(line, filePath, index):
    with open(filePath, 'r') as f:
        lines = f.readlines()
        if index == -1:
            lines.append(line)
        else:
            lines.insert(index, line)
        with open(filePath, 'w') as f:
            f.writelines(lines)
def insertIfNeed(line, findPattern, insertPattern, filePath):
    indexOfLine = indexOf(findPattern, filePath)
    if indexOfLine == -1:
        indexForInsert = indexOf(insertPattern, filePath)
        if indexForInsert != -1:
            insert(line, filePath, indexForInsert)
            print("插入", line)
        else:
            print("不知道往哪插入", line)
    else:
        print("已存在", line)

larkdir = sys.argv[1]
podfilePath = f'{larkdir}/Podfile'
archPath = f'{larkdir}/config/arch.yml'

# 修改 podfile
insertIfNeed(f"  pod 'LookinServer', configurations: ['Debug']\n", r"(.*)pod 'LookinServer'(.*)", r"(.*)pod 'Reveal-SDK'(.*)", podfilePath)
# 修改 arch.yml
insertIfNeed(f"    - LookinServer\n", r"(.*)LookinServer", r"(.*)Reveal-SDK(.*)", archPath)
insertIfNeed(f"    - LookinServer/Core\n", r"(.*)LookinServer/Core", r"(.*)Reveal-SDK(.*)", archPath)


