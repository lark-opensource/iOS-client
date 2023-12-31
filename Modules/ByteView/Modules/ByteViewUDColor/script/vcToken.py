#!/usr/local/bin/python3
# -*- coding: UTF-8 -*-

import os
import string
import requests
import json
from tokenize import String
# import xlwt
# import xlrd

# -------------------------------------- 网络读取 -------------------------------------- #
TokenUrl = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
ListDataUrl = "https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/shtcn8bIUuZTcW0QwUC9J3hUjBh/values/6b0047!A1:F100"
app_id = 'cli_a285a0ceeef81013'
app_secret = '1wjtCup8SlFDOW2OUgj1sb2DFx4wWasv'

def requestToken():
    data = json.dumps({'app_id': app_id,'app_secret': app_secret})
    response = requests.post( url = TokenUrl, data = data, headers = {'content-type': 'application/json, charset=utf-8'} )
    token = json.loads(response.content)["tenant_access_token"]
    print('tenant_access_token结果: ' + str(token))
    return token

def requestListData(token):
    if len(token) <= 0:
        exitout('token empty')
        return

    response = requests.get( url = ListDataUrl, headers = {'Authorization': 'Bearer ' + token} )
    list = json.loads(response.content)["data"]["valueRange"]["values"]
    print('list count: ' + str(len(list)))
    print(list[0])

    array = []  #创建空list
    for rown in range(len(list)):
        cell = list[rown]
        if cell[0] is None:   # 过滤数据中多余的null
            break
        nameStr = formatName(str(cell[1])) 
        lightStr = str(cell[3])
        lightSwiftStr = formatColor(lightStr)
        darkStr = str(cell[4])
        darkSwiftStr = formatColor(darkStr)
        print((str(cell[1]), nameStr, lightStr, lightSwiftStr, darkStr, darkSwiftStr))
        array.append((str(cell[1]), nameStr, lightStr, lightSwiftStr, darkStr, darkSwiftStr))
        print(len(array))
    return array

# -------------------------------------- Excel读取 -------------------------------------- #

def readFromExcel():
    path = os.path.abspath(os.path.dirname(__file__)) + "/VC Token List（新）.xlsx"
    print(path)

    data = xlrd.open_workbook(path)
    table = data.sheets()[0]
    
    rows = table.nrows
    # print(rows)
    # row = table.row_values(0)
    # num = (row[1], row[3], row[4])
    # print(num)

    array = []  #创建空list

    for rown in range(rows):
        cell = table.row_values(rown)
        nameStr = formatName(str(cell[1])) 
        lightStr = str(cell[3])
        lightSwiftStr = formatColor(lightStr)
        darkStr = str(cell[4])
        darkSwiftStr = formatColor(darkStr)
        # print((str(cell[1]), nameStr, lightStr, lightSwiftStr, darkStr, darkSwiftStr))
        array.append((str(cell[1]), nameStr, lightStr, lightSwiftStr, darkStr, darkSwiftStr))

    print(len(array))
    return array

def formatName(nameStr):
    if len(nameStr):
        arr = nameStr.split('-')
        for index in range(len(arr)):
            if index == 0 and arr[0] == "vctoken":
                arr[0] = "vcToken"
            else:
                arr[index] = arr[index].capitalize() 
        return ''.join(arr)
    else:
        return ''

def formatColor(colorStr):
    if len(colorStr):
        colorNewStr = colorStr.replace(", ", ",")
        arr = colorNewStr.split(',')
        if len(arr) == 1:
            return formatColorName(arr[0])
        elif len(arr) == 2:
            return formatColorName(arr[0]) + formatColorAlpha(arr[1])
        else:
            exitout("无法识别颜色格式")
    else:
        return ''

def formatColorName(colorStr):
    if len(colorStr):
        if colorStr.startswith("#"):    # #BCCCE5
            return "rgb(" + colorStr.replace("#", "0x") + ")"
        elif ("-" in colorStr) or ("/" in colorStr):  # primary/pri-400
            str = colorStr.replace("/", "-")
            arr = str.split('-')
            for index in range(len(arr)):
                if index > 0:
                    arr[index] = arr[index].capitalize()                     
            return "UDColor." + ''.join(arr)
        elif colorStr.endswith("0"):   # N600
            return "UDColor." + colorStr
        else: 
            exitout("无法识别颜色格式")
    else:
        exitout("无法识别颜色格式")

def formatColorAlpha(alphaStr):
    if len(alphaStr) and alphaStr.endswith("%"):
        return ".withAlphaComponent(" + str(int(alphaStr.replace("%", "")) * 0.01) + ")"
    else:
        exitout("无法识别颜色格式")
 
def exitout(str):
    print(str)
    os._exit()


# -------------------------------------- 组装代码 -------------------------------------- #

NameExtensionMould = "    static let name1 = UDColor.Name(\"name2\")"
TokenMould = "    public static var name1: UIColor {\n        return UDColor.getValueByKey(.name1) ?? lightColor & darkColor\n    }"
UIColorExtensionMould = "    /// name1, lightColor darkColor\n    public static var name1: UIColor { return UDColor.name1 }"
ThemeColorMould = "        case .name1: return UIColor.ud.name1"

def creatNameExtension(dataArray):
    result = ""
    for data in dataArray:
        result = result + "\n" + NameExtensionMould.replace("name1", data[1]).replace("name2", data[0])

    # print(result)
    return result

def creatToken(dataArray):
    result = ""
    for data in dataArray:
        result = result + "\n\n" + TokenMould.replace("name1", data[1]).replace("lightColor", data[3]).replace("darkColor", data[5])
    # print(result)
    return result

def creatUIColorExtension(dataArray):
    result = ""
    for data in dataArray:
        result = result + "\n\n" + UIColorExtensionMould.replace("name1", data[1]).replace("lightColor", data[2]).replace("darkColor", data[4])
    # print(result)
    return result

def creatThemeColor(dataArray):
    result = ""
    for data in dataArray:
        result = result + "\n" + ThemeColorMould.replace("name1", data[1])
    # print(result)
    return result    


inputValue = input('输入“1”，则通过api接口自动下载数据(需要pip install requests), \n输入“2”，则自己导出Excel到本地(使用先安装xlrd，命令：pip install xlrd==1.2.0，导出https://bytedance.feishu.cn/sheets/shtcn8bIUuZTcW0QwUC9J3hUjBh为Excel到当前目录)\n: ')

if inputValue == "1":
    token = requestToken()
    dataArray = requestListData(token)
elif inputValue == "2":
    dataArray = readFromExcel()
else:
    print('输入有误请重新输入')
    os._exit()

token = requestToken()
dataArray = requestListData(token)

nameExtension = creatNameExtension(dataArray)
token = creatToken(dataArray)
colorExtension = creatUIColorExtension(dataArray)
themeColor = creatThemeColor(dataArray)

path = os.path.abspath(os.path.dirname(__file__)) + "/UIColor+VC"
with open(path + ".txt", "r") as f:  # 打开文件 
    tempTxt = f.read()  # 读取文件

finalTxt = tempTxt.replace("creatNameExtension", nameExtension).replace("creatToken", token).replace("creatUIColorExtension", colorExtension).replace("creatThemeColor", themeColor)
print(finalTxt)
filePath = os.path.abspath(os.path.dirname(os.path.dirname(__file__))) + '/src/UIColor+VC.swift'
print(filePath)
fo = open(filePath, "w")
fo.write(finalTxt) 
fo.close()
print("执行结束")