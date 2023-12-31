#!/usr/bin/env python
# coding=UTF-8

import re
import sys
import os

# 参数为Lark Podfile path
print '''
------------------------------------------------
* 这个脚本用于对比Lark Podfile和 LarkDocs Podfile Pod版本号
* 将LarkDocs Pod版本号升级到Lark的 Pod版本号，减少人工对比的时间
* 目前只能识别 类似"pod 'PodName', 'PodVersion'"格式的Pod
* 对于参数化pod版本号的配置无法识别，需要人工干预。
* 用法：
* 在项目根录执行: 
* ‘bin/LarkDocsUpgrade.py Path_To_Lark_Podfile’
------------------------------------------------
'''

distPodfile = sys.argv[1]
# 上级目录
podfilePath = os.path.abspath(os.path.join(os.path.dirname(__file__), "..")) + "/Podfile"
print podfilePath

class Pod:
   def __init__( self, name='', ver=''):
      self.name = name
      self.ver = ver

def findUpdatedPod(pod, pods):
  if pod == None:
    return
  for p in pods:
    if p == None:
      break
    if pod.name == p.name and pod.ver != p.ver:
      # print(pod.name, "curVer:", pod.ver, "newVer:", p.ver)
      return p

def isPodLine(line):
  newLine = line.strip()
  pattern = re.compile( r"pod '[a-zA-Z0-9]+', '.+'.*")
  matchObj = pattern.match(newLine)
  return matchObj != None

def parsePodInfo(line):
  newLine = line.strip()
  components = re.findall("'[a-zA-Z0-9\.\-]+'", newLine)
  if len(components) >= 2:
    pod = Pod()
    pod.name = components[0]
    pod.ver = components[1]
    # print(pod.name, pod.ver)
    return pod

# 从podfile解析出pod信息
def parsePods(podfilePath):
  skipPods = []# ["'RustPB'", "'BootManager'"] LarkDocs 这两个pod不跟随Lark
  with open(podfilePath) as  f1:
    f11 = f1.readlines()
  pods = []
  for l in f11:
   """这里读到的每一行内容,解析pod"""
   line = l.strip()#除去每行的换行符
   if isPodLine(l):
     components = re.findall("'[a-zA-Z0-9\.\-]+'", line)
     if len(components) >= 2:#包含podname 和 podversion
      pod = Pod()
      pod.name = components[0]
      pod.ver = components[1]
      print pod.name
      if pod.name not in skipPods:
        print pod.name + "not in skipPods"
        pods.append(pod)
  return pods

# 获取larkMessengerversion
def getLarkMessengerPodLine(file):
  with open(file) as  f1:
    f11 = f1.readlines()
  for l in f11:
    if "messenger_pod_version = " in l:
      return l

distPods = parsePods(distPodfile)
newLarkMessengerPodLine = getLarkMessengerPodLine(distPodfile)


with open(podfilePath) as file:
  lines = file.readlines()
file_data = ""
for l in lines:
  if isPodLine(l):
    pod = parsePodInfo(l)
    newVersionPod = findUpdatedPod(pod, distPods)
    if newVersionPod:# 替换版本号
      p = "pod %s, '[a-zA-Z0-9\.\-]+'"%(newVersionPod.name)
      newpod = "pod %s, %s"%(newVersionPod.name, newVersionPod.ver)
      newline = re.sub(p, newpod, l)
      print("old pod:", l.strip())
      print("updated: ", newline.strip()) 
      file_data += newline
    else:
      file_data += l
  # elif "messenger_pod_version = " in l:
  #   file_data += newLarkMessengerPodLine
  else:
    file_data += l

with open(podfilePath, "w") as f:
  f.write(file_data)



print "end!"



