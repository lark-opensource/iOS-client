import os
import subprocess
import re
import json
from biplist import *
import time
import daemon
import requests
import datetime


def getRemote(name, file_list):
    path = "./" + name
    if not os.path.exists(path):
        os.mkdir(path)
    os.chdir(path)
    os.system("git init")
    os.system("git config core.sparsecheckout true")
    if not os.path.exists(".git/info"):
        os.mkdir(".git/info")
    for file in file_list:
        os.system("echo " + file + " >> .git/info/sparse-checkout")
    os.system("git remote rm origin")
    os.system("git remote add -f origin gitr:ee/lark/" + name)
    os.chdir("../")


def init():
    getRemote("ios-client", ["Podfile"])
    getRemote("android-client", ["config/ext-info/irtc.gradle", "config/config.gradle"])
    getRemote("pc-client", ["larklets", "app/library", "app/package.json"])


def getPCTags(min_version):
    path = os.getcwd()
    os.chdir(path + "/pc-client")
    result = subprocess.getoutput("git tag --list").split("\n")
    os.chdir(path)
    tag_list = []

    for tag in result:
        tag = tag.strip()
        if re.match('V', tag) and shouldQueryVersion(tag.split("V")[-1],
                                                                          min_version):
            tag_list.append(tag)
    return tag_list

def getPCBranchs(min_version):
    path = os.getcwd()
    os.chdir(path + "/pc-client")
    result = subprocess.getoutput("git branch -r").split("\n")
    os.chdir(path)
    branch_list = []

    for branch in result:
        branch = branch.strip()
        if re.match('origin/builds/beta/', branch) and shouldQueryVersion(branch.split("origin/builds/beta/")[-1],
                                                        min_version):
            branch_list.append(branch.split("origin/")[-1])
    return branch_list

def getAndroidBranchs(min_version):
    path = os.getcwd()
    os.chdir(path + "/android-client")
    result = subprocess.getoutput("git branch -r").split("\n")
    os.chdir(path)
    branch_list = []
    for branch in result:
        branch = branch.strip()
        if re.match('origin/v/', branch) and shouldQueryVersion(branch.split("origin/v/")[-1], min_version):
            branch_list.append(branch.split("origin/")[-1])

    return branch_list


def getIOSTags(min_version):
    path = os.getcwd()
    os.chdir(path + "/ios-client")
    result = subprocess.getoutput("git tag --list").split("\n")
    os.chdir(path)
    branch_list = []

    for branch in result:
        branch = branch.strip()
        if shouldQueryVersion(branch, min_version):
            branch_list.append(branch)
    return branch_list


def getIOSVersion(name, tag):
    path = os.getcwd()
    os.chdir("./ios-client")
    os.system("git fetch")
    os.system("git checkout " + tag)
    f = open("Podfile", "r")
    lines = f.readlines()
    f.close()
    for line in lines:
        if name in line:
            break
    rtc_line = line.strip()
    rtc_version = rtc_line.split(",")[-1].strip()
    rtc_version = rtc_version[1:-1]
    os.chdir(path)
    return rtc_version


def getAndroidRtcVersion(branch):
    path = os.getcwd()
    os.chdir("./android-client")
    os.system("git checkout " + branch)
    f = open("./config/ext-info/irtc.gradle", "r")
    lines = f.readlines()
    f.close()
    for line in lines:
        if "irtc" in line:
            rtc_line = line
    rtc_version = rtc_line.split("version:")[-1].split("-")[0]
    rtc_version = rtc_version.strip()[1:]
    os.chdir(path)
    return rtc_version

def getAndroidRustVersion(branch):
    path = os.getcwd()
    os.chdir("./android-client")
    os.system("git checkout " + branch)
    f = open("./config/config.gradle", "r")
    lines = f.readlines()
    f.close()
    for line in lines:
        if "rust_sdk_java_wire" in line:
            version_line = line
    version = version_line.split("rust-sdk-java-wire:")[-1].split("'")[0]
    os.chdir(path)
    version = version.strip()
    return version

def getPCRtcVersion(branch):
    path = os.getcwd()
    os.chdir("./byteview-pc-sdk")
    os.system("git checkout " + branch)
    f = open("./package.json","r")
    lines = f.readlines()
    f.close()
    dependencies = json.loads("".join(lines))
    os.chdir(path)
    return dependencies["rtcSDKVersion"]

def getPCRustVersion(branch):
    path = os.getcwd()
    os.chdir("./byteview-pc-sdk")
    os.system("git checkout " + branch)
    f = open("./package.json", "r")
    lines = f.readlines()
    f.close()
    os.chdir(path)
    return json.loads("".join(lines))["version"]

def getPCVersionDict(branch):
    path = os.getcwd()
    os.chdir("./pc-client")
    os.system("git checkout " + branch)
    f = open("./larklets/byted-larklet-byteview/package.json", "r")
    lines = f.readlines()
    f.close()
    dependencies = json.loads("".join(lines))["dependencies"]
    os.chdir(path)
    print('meeting:', dependencies['@byteview/meeting'])
    print('pc-sdk', dependencies['@byteview/pc-sdk'])
    return dependencies


def updateVersion(data_dict):
    url = "https://cloudapi.bytedance.net/faas/services/ttxy51/invoke/save_version"

    headers = {'Content-Type': 'application/json'}

    response = requests.request(
        "POST",
        url,
        headers=headers,
        data=json.dumps(data_dict)
    )

    print(response.text)


def getMinVersionNumber():
    all_ios_tag = []
    path = os.getcwd()
    os.chdir(path + "/ios-client")
    result = subprocess.getoutput("git tag --list").split("\n")
    os.chdir(path)

    for branch in result:
        branch = branch.strip()
        all_ios_tag.append(branch)

    big_number_version = []
    for tag in all_ios_tag:
        if tag[0].isdigit():
            if "-" in tag:
                tag = tag.split("-")[0]
            tag_array = tag.split(".")
            if len(tag_array) == 3 and tag_array[0].isdigit() and tag_array[1].isdigit():
                number_version = int(tag_array[0]) * 100 + int(tag_array[1])
                if number_version not in big_number_version:
                    big_number_version.append(number_version)
    big_number_version.sort()
    if len(big_number_version) > 4:
        return big_number_version[-4]
    else:
        return big_number_version[0]


def gitPull(name):
    path = os.getcwd()
    os.chdir("./" + name)
    res = os.system("git pull")
    print(res)
    os.system("echo 'pull finish'")
    os.chdir(path)


def shouldQueryVersion(version, min_version):
    if version:
        if "-" in version:
            version = version.split("-")[0]
        version_array = version.split(".")
        if len(version_array) == 3 and version_array[0].isdigit() and version_array[1].isdigit():
            number_version = int(version_array[0]) * 100 + int(version_array[1])
            if number_version >= min_version:
                return True
    return False


def querySDK(os):
    print("querySDK: " + os)
    min_version = getMinVersionNumber()
    print("min_version",min_version)
    data = {"os": os}
    array = []
    if os == "android":
        branch_list = getAndroidBranchs(min_version)
        for branch in branch_list:
            new_version = {"lark_version": branch.split("v/")[-1], "rtc_version": getAndroidRtcVersion(branch),
                           "time": getCreateTime("android-client", branch, "branch"), "rust_sdk": getAndroidRustVersion(branch)}
            array.append(new_version.copy())
    elif os == "ios":
        branch_list = getIOSTags(min_version)
        for branch in branch_list:
            new_version = {"lark_version": branch, "rtc_version": getIOSVersion("ByteRtcSDK", branch),
                           "time": getCreateTime("ios-client", branch, "tag"), "rust_sdk": getIOSVersion("pod 'RustPB'", branch)}
            array.append(new_version.copy())
    else:
        tag_list = getPCTags(335)
        print('tag_list', tag_list)
        for tag in tag_list:
            print(tag)
            new_version = {"lark_version": tag.split("V")[-1], "rtc_version": getPCRtcVersion(tag),
                           "time": getCreateTime("pc-client", tag, "tag"), "rust_sdk": getPCRustVersion(tag)}
            dependencies = getPCVersionDict(tag)
            new_version['pc-sdk'] = dependencies['@byteview/pc-sdk']
            new_version['byteview-pc'] = dependencies['@byteview/meeting']
            array.append(new_version.copy())
        branch_list = getPCBranchs(335)
        for branch in branch_list:
            new_version = {"lark_version": branch.split("builds/beta/")[-1] + "-正式版", "rtc_version": getPCRtcVersion(branch),
                           "time": getCreateTime("pc-client", branch, "branch"), "rust_sdk": getPCRustVersion(branch)}
            dependencies = getPCVersionDict(branch)
            new_version['pc-sdk'] = dependencies['@byteview/pc-sdk']
            new_version['byteview-pc'] = dependencies['@byteview/meeting']
            array.append(new_version.copy())

    data["array"] = array
    updateVersion(data)



def getCreateTime(name, tag, type):
    path = os.getcwd()
    os.chdir("./" + name)
    order = "git tag -l --sort=-creatordate --format='%(creatordate:short):  %(refname:short)'"
    if type == "branch":
        order = "git branch -lr --sort=-creatordate --format='%(creatordate:short):  %(refname:short)'"

    result = subprocess.getoutput(order)
    os.chdir(path)

    lines = result.split("\n")
    for line in lines:
        if tag in line:
            print(line)
            break

    return line.split(":")[0]


def timeRun():
    os.chdir("/home/ruanmingzhe/queryRtc")
    os.system("kinit -kt ruanmingzhe.keytab ruanmingzhe@BYTEDANCE.COM")
    gitPull("android-client")
    querySDK("android")
    gitPull("pc-client")
    querySDK("pc")
    gitPull("ios-client")
    querySDK("ios")


if __name__ == "__main__":
    
    with daemon.DaemonContext():
        while True:
            timeRun()
            time.sleep(1 * 60 * 60)