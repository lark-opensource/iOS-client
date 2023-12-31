
# -*- coding: utf-8 -*

import requests
import os
import types
import json
import sys

# 递归遍历字典，将所有的value为bool的key-value返回
def checkDict( d ):
	result = []
	for key, value in d.items():
		if isinstance(value, bool):
			result.append((key, value))
		elif isinstance(value, dict):
			result = result + checkDict(value)
	return result


def getMinaGAKey():
	headers = {'cookie': 'bear-session=XN0YXJ0-40ebd5fc-263f-43a3-99e5-6ad22b0bdabg-WVuZA; osession=XN0YXJ0-40ebd5fc-263f-43a3-99e5-6ad22b0bdabg-WVuZA; session=XN0YXJ0-40ebd5fc-263f-43a3-99e5-6ad22b0bdabg-WVuZA; lang=zh; _csrf_token=20843c4152e44f52521cdd94ccbd6fd1dc657d9f-1596956391',
		       'user-agent': 'DocsSDK/3.31.2 Lark/3.31.0-alpha CFNetwork/unknown Darwin/19.5.0 Mobile iPhone10,3 iOS/13.5.1',
		       'doc-version-name': '3.31.0-alpha'}
	params = {'appId': 2, 
	          'device_id': '55490521921', 
	          'isPad': False, 
	          'platform': 'ios', 
	          'tenant_id': '6857899377835393025', 
	          'user_id': '6857899377927651329',
	          'version': 'online-1.0'}
	result = requests.post('https://internal-api-space-lf.feishu.cn/space/api/appconfig/get/', data = params, headers = headers)
	print (result.json()["msg"])
	# fg为bool值，且为true
	minaGABoolKey = []
	# fg为bool值，且为false
	minaNoGABoolKey = []
	# fg为可配置，但是配置项有bool值为true的。{key: [subKeys]}
	minaGAConfigKey = {}
	# fg为可配置，但是配置项有bool值为true的。{key: [subKeys]}
	minaNOGAConfigKey = {}

	for key, value in result.json()['data'].items():
		if isinstance(value, bool) and value == True:
			minaGABoolKey.append(key)
		if isinstance(value, bool) and value == False:
			minaNoGABoolKey.append(key)
		if isinstance(value, dict):
			# 检查配置项中是否有bool值
			tupArray = checkDict(value)
			if tupArray:
				ga = []
				noGa = []
				for tup in tupArray:
					if tup[1]:
						ga.append(tup[0])
					else:
						noGa.append(tup[0])
				if ga:
					minaGAConfigKey[key] = ga
				if noGa:
					minaNOGAConfigKey[key] = noGa
	print(minaGABoolKey)
	return minaGABoolKey, minaGAConfigKey, minaNoGABoolKey, minaNOGAConfigKey

def getLarkFG():
	headers = {'cookie': 'session=XN0YXJ0-40ebd5fc-263f-43a3-99e5-6ad22b0bdabg-WVuZA', 
	  		   'user-agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.5.1 Mobile/15E148 Safari/604.1 Lark/3.31.0 LarkLocale/zh_CN SDK-Version/3.28.0'}
	result = requests.get('https://internal-api-lark-api-hl.feishu.cn/settings/v3/?version_code=0_468379&device_id=55490521921&app_channel=Release&version=3.31.0-alpha', headers = headers)
	fgGAKeys = result.json()["data"]["lark_features"]["online"]
	return fgGAKeys

def getMinaFGPath():
	projectPath = os.path.abspath(os.path.join(os.path.abspath(sys.argv[0]), "../../.."))
	minafgPath = projectPath + '/Bizs/SKCommon/src/Business/Configuration/Base/MinaConfigKey.swift'
	return minafgPath

def getLarkFGPath():
	projectPath = os.path.abspath(os.path.join(os.path.abspath(sys.argv[0]), "../../.."))
	lkfgPath1 = projectPath + '/Bizs/SKCommon/src/Business/Common/Models/Drive/DriveFeatureGate.swift'
	lkfgPath2 = projectPath + '/Bizs/SKCommon/src/Business/Common/Models/Wiki/WikiFeatureGate.swift'
	lkfgPath3 = projectPath + '/Bizs/SKCommon/src/Business/Configuration/Base/LKFeatureGating.swift'
	return lkfgPath1, lkfgPath2, lkfgPath3

def getProjectMinaKey():
	fgPath = getMinaFGPath()
	file = open(fgPath)
	lines = file.readlines()
	allFGKeys = []
	for index, line in enumerate(lines):
		if "//" not in line and "@MinaWrapper" in line:
			r = line.split("\"")
			allFGKeys.append(r[1])
	file.close()
	return allFGKeys

def getProjectLarKFGKey():
	paths = getLarkFGPath()
	lines = []
	for path in paths:
		file = open(path)
		lines = lines + file.readlines()
		file.close()

	allFGKeys = []
	for index, line in enumerate(lines):
		if "//" not in line and "@FeatureGating" in line:
			r = line.split("\"")
			allFGKeys.append(r[1])
	return allFGKeys

keys = getMinaGAKey()
minaGABoolKey = keys[0]
minaGAConfigKey = keys[1]
minaNoGABoolKey = keys[2]
minaNOGAConfigKey = keys[3]
larkGAKey = getLarkFG()

def resetWarning():
	paths = []
	paths.append(getMinaFGPath())
	paths += getLarkFGPath()
	for path in paths:
		file = open(path)
		lines = file.readlines()
		with open(path, 'w') as f:
			for l in lines:
				if "@available" not in l:
					f.write(l)
			f.close()

def addWarning():
	# mina部分
	fgPath = getMinaFGPath()
	file = open(fgPath)
	lines = file.readlines()
	file.close()

	for index, line in enumerate(lines):
		if "//" not in line and "@MinaWrapper" in line:
			key = line.split("\"")[1]
			# fg为Bool
			if key in minaGABoolKey:
				lines[index] = "    @available(*, deprecated, message: \"This feature is GA\")\n" + line
			# fg为配置项
			if key in minaGAConfigKey.keys():
				lines[index] = "    @available(*, deprecated, message: \"Some config is GA, please check\")\n" + line

	with open(fgPath, 'w') as f:
		for line in lines:
			f.write(line)
		f.close()
	#lark fg部分
	for path in getLarkFGPath():
		file = open(path)
		lines = file.readlines()
		file.close()
		for i, line in enumerate(lines):
			if "//" not in line and "@FeatureGating" in line:
				key = line.split("\"")[1]
				# fg为Bool
				if key in larkGAKey:
					lines[i] = "    @available(*, deprecated, message: \"This feature is GA\")\n" + line
		with open(path, 'w') as f:
			for line in lines:
				f.write(line)
			f.close()

def recordMinaFG():
	projectPath = os.path.abspath(os.path.join(os.path.abspath(sys.argv[0]), "../../.."))
	fileName = projectPath + "/SpaceDemo/Scripts/Mina_FG_key.txt"
	projectKeys = getProjectMinaKey()
	projectKeys.sort()
	with open(fileName, 'w') as file:
		file.write("————类型为Bool的FG，值为true（GA）————\n\n")
		minaGABoolKey.sort()
		for value in minaGABoolKey:
			file.write(value + "\n")

		file.write("\n————类型为Bool的FG，值为false（未GA）————\n\n")
		minaNoGABoolKey.sort()
		for value in minaNoGABoolKey:
			file.write(value + "\n")

		file.write("\n————类型为配置项的FG，配置项中值为true（GA）————\n\n")
		for key, value in sorted(minaGAConfigKey.items()):
			file.write("key: " + key + "\n")
			value.sort()
			for r in value:
				file.write("  " + r + "\n")

		file.write("\n————类型为配置项的FG，配置项中值为false（未GA）————\n\n")
		for key, value in sorted(minaNOGAConfigKey.items()):
			file.write("key: " + key + "\n")
			value.sort()
			for r in value:
				file.write("  " + r + "\n")

		file.write("\n————已经清理的bool key(未在代码中出现的key)————\n\n")
		for value in minaGABoolKey:
			if value not in projectKeys:
				file.write(value + "\n")

		file.write("\n————已经清理的config key(未在代码中出现的key)————\n\n")
		for key, value in sorted(minaGAConfigKey.items()):
			if key not in projectKeys:
				file.write(key + "\n")
		file.close()

def recordLarkFG():
	projectPath = os.path.abspath(os.path.join(os.path.abspath(sys.argv[0]), "../../.."))
	fileName = projectPath + "/SpaceDemo/Scripts/Lark_FG_key.txt"
	projectKeys = getProjectLarKFGKey()
	projectKeys.sort()
	with open(fileName, 'w') as file:
		file.write("————类型为Bool的FG，值为true（GA）————\n\n")
		for value in projectKeys:
			if value in larkGAKey:
				file.write(value + "\n")

		file.write("\n————类型为Bool的FG，值为false（未GA）————\n\n")
		for value in projectKeys:
			if value not in larkGAKey:
				file.write(value + "\n")
		file.close()

resetWarning()
addWarning()
recordMinaFG()
recordLarkFG()


