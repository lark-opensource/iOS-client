#!/usr/bin/python3
# -*- coding: UTF-8 -*-
import argparse
import os
import shutil
import json
import re
import requests
import urllib
from Crypto.Cipher import AES
import base64
import hashlib


def fetchMetaData(appId):
    if appId == "":
        print "⛔ ERROR: fetchMetaData with empty appId"
        return
    requestURL = "https://open.feishu.cn/open-apis/mina/v2/getAppMeta"
    headers = {'content-type':'application/json',
               'accept':'*/*',
               'called_from':'miniapp',
               'x-tma-host-sessionid':'XN0YXJ0-6a1660dd-c1a5-48bf-ab15-02d6bc42568g-WVuZA',
               'accept-language':'zh-cn',
               'accept-encoding':'gzip, deflate',
               'x-request-id':'021616486764590e8eb8ee96d48128a140ae449377fd6dfeqbbbb',
               #'content-length':'495',
               'user-agent':'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Ecosystem/3.45.0 EEMicroApp/1.9.41.2',
               'x-request-id-op':'1-289e65d2-46bbc140-115ed406',
               'domain_alias':'open',
               'x-tt-logid':'021616486764590e8eb8ee96d48128a140ae449377fd6dfeqbbbb'}
    body = {
    "app_version": "3.45.0",
    "appid": appId,
    "bdp_device_platform": "iphone",
    "bdp_version_code": "3.45.0",
    "language": "ZH-CN",
    "platform": "ios",
    "sessionid": "XN0YXJ0-6a1660dd-c1a5-48bf-ab15-02d6bc42568g-WVuZA",
    "token": "",
    "ttcode": "tYpQQypn9ni1%2FPqZj4U6mRCh8IrwyGdvvYfgM8XlXu7WQu532IzmYCSF8KNx1TRs%2FwnsOjeh%2FH%2FstFoO8sJqRO2lPrbmxQIXgoB8uaqxwXvSa%2BzlsGlRAw79ys%2FkPmL%2FPL4eBHyb8MZova4ceUvdq17uD5JfwpyEJL56%2B%2BmlTXU%3D",
    "version": "current"}
    #self.aesKeyA = "B4huRIrpmThGgYiY"
    #self.aesKeyB = "tfQ2Sw04GMEdwUy4"
    #ttcode = "tYpQQypn9ni1%2FPqZj4U6mRCh8IrwyGdvvYfgM8XlXu7WQu532IzmYCSF8KNx1TRs%2FwnsOjeh%2FH%2FstFoO8sJqRO2lPrbmxQIXgoB8uaqxwXvSa%2BzlsGlRAw79ys%2FkPmL%2FPL4eBHyb8MZova4ceUvdq17uD5JfwpyEJL56%2B%2BmlTXU%3D",
    #

    response = requests.post(requestURL, json=body, headers = headers)
    return response.json()["data"]

def decrypt(text):
    key = "B4huRIrpmThGgYiY"
    iv = "tfQ2Sw04GMEdwUy4"
    mode = AES.MODE_CBC
    encry_text = base64.b64decode(text)
    cryptor = AES.new(key, mode, iv)
    plain_text = cryptor.decrypt(encry_text)
    return plain_text.rstrip('')

def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

if __name__ == '__main__':
    #read appId from file line by line
    file = open('appIds.txt', 'r')
    lines = file.readlines()
    print "begin to execute fetch meta script"
    metaList = []
    for line in lines:
        line = line.strip()
        print "fetch meta data with appId:" + line
        jsonResponse = fetchMetaData(line)
        metaList.append(jsonResponse)
        print "✅ meta fetch successfully, appId:"+line
    if len(lines) != len(metaList):
        print "⛔ ERROR:data count not match, fatal error"
    else:
        print "✅ meta list count check successfully"
    print "saving meta list to appMetaList.json in current working directory"
    with open('appMetaList.json', 'w') as outfile:
        json.dump(metaList, outfile)
    print "✅ meta appMetaList.json write successfully"
    count = 0
    for meta in metaList:
        packageURL = str(meta["path"][0])
        appId = meta["appid"].rstrip()
        fileName = unicode.encode('%s.pkg' % (appId), 'utf-8')
        print "packageURL: "+packageURL
        print "fileName: "+fileName
        print "try to download package..."
        packageData = urllib.urlopen(packageURL).read()
        print "package downloaded successfully"
        packageFile = open(fileName, 'w')
        packageFile.write(packageData)
        packageFile.close()
        print "package write successfully"
        decryptedMD5 = decrypt(meta["md5"]).strip()
        fileMD5 = md5(fileName)
        if decryptedMD5.startswith(fileMD5):
            count += 1
            print "✅ package file check successfully:"+fileName
        else:
            print "⛔ ERROR: please check file md5 by yourself."
            print "decrypted md5:"+decryptedMD5
            print "package file md5:" + decryptedMD5
        print appId + "package write finished."
    if count == len(lines):
        print "✅✅✅ CONGRATULATIONS: all preset packages download successfully"
    else:
        print "⚠️ ATTENTION: packages download with error, please check log carefully!"

