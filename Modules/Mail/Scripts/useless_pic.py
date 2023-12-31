import os
import io
import re
import time

#找到文件中所有pic的名字，并输出
def checkfile(filename, fileroot):
    lowername = filename.lower()
    res = []
    if lowername == 'contents.json':
        filepath = os.path.join(fileroot, filename)
        f = io.open(filepath,'r', encoding='utf-8')
        for line in f:
            pattern1 = "\"([^:\s]*)@2x.png\""
            pattern2 = "\"([^:\s]*)@3x.png\""
            pattern3 = "\"([^\",@]*).png\""
            group1 = re.findall(pattern1, line)
            group2 = re.findall(pattern2, line)
            group3 = re.findall(pattern3, line)
            group1 = group1 + group2 + group3
            for word in group1:
                if word not in res:
                    res.append(word)
        f.close()
    return res

# 检查str是否在file中，如果存在，则打印file名字
def hasStrInfile(picfunc,filepath):
    if filepath.endswith('swift') == False:
        return False
    
    f = io.open(filepath, 'r', encoding='utf-8')
    for line in f:
        lineNoSpace = line.replace(' ','')
        picfunc = picfunc.replace(' ', '')
        if lineNoSpace.find(picfunc) >= 0:
            f.close()
            return True
    f.close()
    return False

# 从根目录遍历所有文件，找能匹配str1的文件
def hasStrInDir(pics, dirpath, needGen):
    picDic = {}
    resPics = []
    for root, dirs, files in os.walk(dirpath):
        for file in files:
            filepath = os.path.join(root, file)
            for pic in pics:
                picfunc = pic
                if needGen == True:
                    picfunc = generatePicfunc(pic)
                flag = hasStrInfile(picfunc, filepath)
                if flag == True:
                    array = picDic.get(pic)
                    if array:
                        array.append(file)
                    else:
                        picDic[pic] = [file]
    # 存在于 非 Resources.swift 文件，则说明在使用
    for key, value in picDic.items():
        flag = False
        for file in value:
            if file != 'Resources.swift':
                flag = True
                break
        if flag == False:
           resPics.append(key) 
    return resPics

def getStaticNames(pics):
    res = []
    picRes = []
    for pic in pics:
        picfun = generatePicfunc(pic)
        picfun = picfun.replace(' ', '')
        picfun = picfun.replace('(', '')
        picfun = picfun.replace(')', '')
        res.append(picfun)
    
    
    f = io.open(resourcePath,'r', encoding='utf-8')
    for line in f:
        line = line.replace(' ','')
        line = line.replace('(', '')
        line = line.replace(')', '')
        for tem in res:        
            pattern = "staticlet(.*)=" + tem
            group = re.findall(pattern,line)
            for i in group:
                picRes.append(i)
    f.close()
    return picRes

def generatePicfunc(pic):
    return 'Resources.image(named: \"' + pic + '\")' 

def findPicName(otherNames):
    res = []
    picRes = []
    for pic in otherNames:
        pic = pic.replace(' ', '')
        pic = pic.replace('(', '')
        pic = pic.replace(')', '')
        res.append(pic)
    
    
    f = io.open(resourcePath,'r', encoding='utf-8')
    for line in f:
        line = line.replace(' ','')
        line = line.replace('(', '')
        line = line.replace(')', '')
        for tem in res:        
            pattern = "staticlet" + tem + '=Resources.imagenamed:\"' + '([^\"]*)' + '\"'
            group = re.findall(pattern,line)
            for i in group:
                picRes.append(i)
    f.close()
    return picRes

def checkUseless(picdir, codepath):
    allPics = []
    for root, dirs, files in os.walk(picdir):
        for file in files:
            pics = checkfile(file, root)
            if len(pics) > 0:
                allPics = allPics + pics
    allPics = hasStrInDir(allPics, codepath, True)
    otherNames = getStaticNames(allPics)
    if len(otherNames) > 0:
        picfuncs = hasStrInDir(otherNames, codepath, False)
        picfuncs = findPicName(picfuncs)
        if len(picfuncs) > 0:    
            for pic in picfuncs:
                print(pic)
        else:
            print('no useless pic find')
                
start = time.time()
curPath = os.getcwd()
upPath = os.path.abspath('..')
mailsdkPath = os.path.join(upPath, 'MailSDK')
resourcePath = os.path.join(mailsdkPath, 'Mail/Config/Resources.swift')
picPath = os.path.join(mailsdkPath, 'Resources/SupportFiles/Assets.xcassets')
checkUseless(picPath,mailsdkPath)
end = time.time()
print (end - start)
 
            
