import requests
import json
import os
import shutil

# 目标写入路径
targetPath = './../TTMicroApp/Timor/Core/OPAPI/Define'

# 切换到脚本文件路径
os.chdir(os.path.abspath(os.path.dirname(__file__)))

rootPath = os.path.abspath(targetPath)
rootPathBackup = rootPath + '.backup'
tmpPath = '/tmp/apiTmpGenCodes'

print('Target Path: '+rootPath)

if os.path.exists(tmpPath):
    shutil.rmtree(tmpPath)

url = 'https://cloudapi.bytedance.net/faas/services/ttobva/invoke/apiCodeGen?platform=iOS'
res = requests.get(url)

json_data = json.loads(res.text)

if os.path.exists(rootPathBackup):
    shutil.rmtree(rootPathBackup)

for fileItem in json_data:
    fileName = fileItem['path'] + '/' + fileItem['name']
    filePath = tmpPath + '/' + fileName
    os.makedirs(os.path.dirname(filePath), exist_ok=True)

    print('START:'+rootPath+'/'+fileName)

    with open(filePath, 'w') as source_file:
        source_file.write(fileItem['content'])

    print('DONE')

if os.path.exists(rootPath):
    os.rename(rootPath, rootPathBackup)

os.makedirs(os.path.dirname(rootPath), exist_ok=True)

os.rename(tmpPath, rootPath)

if os.path.exists(rootPathBackup):
    shutil.rmtree(rootPathBackup)

print("Code Gen Success!")
