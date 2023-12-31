#!/usr/bin/python3
import argparse
import logging
import urllib.request
import os
import zipfile
import shutil
from socket import timeout
from urllib.error import HTTPError, URLError
import json
import re

def removeFileOrDir(path):
    if os.path.isfile(path):
        logging.info("file " + path + " exist")
        os.remove(path)
    if os.path.isdir(path):
        logging.info("dir " + path + " exist")
        shutil.rmtree(path)
    remove = not os.path.isfile(path) and not os.path.isdir(path)
    if remove:
        logging.info("remove " + path + " success")
    else:
        logging.error("remove " + path + " failed")
    return remove

def unzip(sourceFile, targetPath):
    '''
    :param sourceFile: 待解压zip路径
    :param targetPath: 目标文件目录
    :return:
    '''
    file = zipfile.ZipFile(sourceFile, 'r')
    file.extractall(targetPath)
    logging.info('success to unzip file!')

def getJSSDKZipUrl(larkVersion):
    '''
    :param larkVersion: 对应的lark的版本
    :return: 返回对应的资源地址
    '''
    logging.info("start get jssdk zip url for lark " + larkVersion)
    configUrl = "https://open.feishu.cn/config/get?appId=1&version=1&larkVersion={0}&paltform=mobile".format(larkVersion)
    try:
        response = urllib.request.urlopen(configUrl, timeout=30)
        encoding = response.info().get_content_charset('utf-8')
        configData = response.read()
        configString = str(configData.decode(encoding))
        configJson = json.loads(configString)
        jssdk = configJson["jssdk"]
        if not jssdk:
            logging.error("get jssdk for [%s] fail " + configJson)
            return None
        latestSDKUrl = jssdk["latestSDKUrl"]
        if not latestSDKUrl:
            logging.error("get jssdk zip for [%s] fail \n [%s]", larkVersion, json.dumps(jssdk, sort_keys=True, indent=4))
            return None
        logging.info("get jssdk zip for [%s] result : [%s]", larkVersion, latestSDKUrl)
        return latestSDKUrl
    except (HTTPError, URLError) as error:
        logging.error('Data of config not retrieved because [%s] URL: [%s]', error, url)
    except timeout:
        logging.error('config retrieved timed out - URL [%s]', url)
    except ValueError as error:
        logging.error('config json decode failed %s', error)
    except Exception as error:
        logging.error('unknown exception %s', error)

def getLarkVersion():
    with open("../TTMicroApp.podspec") as f:
        for line in f:
            match = re.findall(r"\ss.version\s+=\s'(.+?)'$", line)
            if len(match) > 0:
                print(match)
                return match[0]
        return None

logfileName = "jssdk_update.log"
removeFileOrDir(os.path.join(os.path.dirname(os.path.realpath(__file__)), logfileName))
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(logfileName),
        logging.StreamHandler()
    ]
)

if __name__ == '__main__':
    workdir = os.path.dirname(os.path.realpath(__file__))
    logging.info("change work dir " + workdir)
    os.chdir(workdir)
    logging.info("start parse parameter")
    parser = argparse.ArgumentParser()
    parser.description = 'please enter jssdk resource url'
    parser.add_argument("-u", "--url", help="specify jssdk url", dest="url", type=str, default=None)
    parser.add_argument("-v", "--larkVersion", help="specify target lark version", dest="larkVersion", type=str, default=None)
    parser.add_argument("-d", "--detectLarkVersion", help="auto detect lark version in TTMicroApp.podspec", action='store_true')
    parser.add_argument("-t", "--type", help="app type, gadget, block(default gadget)", dest="appType", type=str, default=None)
    parser.add_argument("-bv", "--blockitVersion", help="specify target blockit version", dest="blockitVersion", type=str, default=None)

    args = parser.parse_args()
    url = args.url
    larkVersion = args.larkVersion
    detectLarkVersion = args.detectLarkVersion
    appType = args.appType
    blockitVersion = args.blockitVersion
    if not appType: 
        appType = "gadget"
    if not url and not larkVersion:
        logging.error("can not parse parameter jssdk url, try auto detect")
    if larkVersion:
        url = getJSSDKZipUrl(larkVersion)
    if not url and detectLarkVersion:
        logging.info("start detect default lark version")
        detectLarkVersion = str(getLarkVersion())
        if detectLarkVersion:
            logging.info("detect default lark version %s", detectLarkVersion)
            url = getJSSDKZipUrl(detectLarkVersion)
            logging.info("detect default jssdk url %s for lark %s", url, detectLarkVersion)
        else:
            logging.error("can not detect default lark version")
            logging.error("can not parse parameter jssdk url, try input")
    while not url:
        url = input("please input jssdk url: ")
    # start check url
    logging.info("start check jssdk url " + url)
    try:
        response = urllib.request.urlopen(url, timeout=10).read()
    except (HTTPError, URLError) as error:
        logging.error('Data of jssdk not retrieved because %s URL: %s', error, url)
        exit(-2)
    except timeout:
        logging.error('socket timed out - URL %s', url)
        exit(-3)
    else:
        logging.info('Access successful.')
    zipFileName = "jssdk_download.zip"
    zipFilePath = os.path.join(workdir, zipFileName)
    #check old zip file exist
    if not removeFileOrDir(zipFilePath):
        logging.error("remove file failed " + zipFilePath)
        exit(-4)
    #download jssdk
    resultPath, httpMsg = urllib.request.urlretrieve(url, zipFilePath)
    if not os.path.isfile(resultPath):
        logging.error("download jssdk failed: " + url + " " + httpMsg)
        exit(-5)
    else:
        logging.info("download jssdk [" + url + "] success")
    #remove old jssdk unzip folder
    if appType == "gadget":
        unzip_jssdkdir = os.path.join(workdir, "__dev__")
    elif appType == "block":
        unzip_jssdkdir = os.path.join(workdir, "block_jssdk")
    if not removeFileOrDir(unzip_jssdkdir):
        logging.error("remove jssdk folder failed " + unzip_jssdkdir)
        exit(-6)
    unzip(resultPath, workdir)
    logging.info("success update jssdk")
    logging.info("start encrypt jssdk")
    jsHandlerName = "./EncryptJS.sh"
    if appType == "block":
        jsHandlerName = "./BlockJSHandler.sh " + blockitVersion
    if os.system(jsHandlerName) == 0:
        logging.info("success encrypt jssdk")
    else:
        logging.error("encrypt jssdk failed")
        exit(-7)
    # clean jssdk zip
    oldjssdkzip = os.path.join(workdir, "jssdk_download.zip")
    if removeFileOrDir(oldjssdkzip):
        logging.info("clean success " + oldjssdkzip)
