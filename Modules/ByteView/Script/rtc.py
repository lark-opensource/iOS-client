import requests
from requests.auth import HTTPBasicAuth
import json
import os
import sys
import shutil

def getAttachmentUrl(issueKey):
    print("获取附件地址")
    url = "https://jira.bytedance.com/rest/api/2/issue/" + issueKey

    auth = HTTPBasicAuth("jira账号", "jira密码")

    headers = {
        "Accept": "application/json"
    }

    response = requests.request(
        "GET",
        url,
        headers=headers,
        auth=auth,
        data=json.dumps({"fileds": ["attachment"]})
    )

    issue = json.loads(response.text)
    attachments = issue["fields"]["attachment"]
    for attachment in attachments:
        if "symbolicate" in attachment["filename"] and "new" not in attachment["filename"]:
            return attachment["content"]


def getAttachment(url):
    print("获取附件")
    auth = HTTPBasicAuth("jira账号", "jira密码")
    response = requests.request(
        "GET",
        url,
        auth=auth,
    )

    attachment = response.text
    filename = url.split("/")[-1]
    path = "./python_rtc_symbolicate/" + filename
    file = open(path, mode="w")
    file.write(attachment)
    file.close()

    line = attachment.split("Code Type")[0]
    version = line.split("Version:")[-1]
    version = version.split("(")[0]

    aid = filename.split("_")[0]
    if not "beta" in version:
        if aid == "1161":
            version = version + "-inhouse"
        else:
            version = version + "-appstore"
    return version, filename


def firstRun():
    path = "./python_rtc_symbolicate"
    if not os.path.exists(path):
        os.mkdir(path)
    path = path + "/ios-client"
    if not os.path.exists(path):
        os.mkdir(path)
    os.chdir("./python_rtc_symbolicate/ios-client")
    os.system("git init")
    os.system("git config core.sparsecheckout true")
    if not os.path.exists(".git/info"):
        os.mkdir(".git/info")
    os.system("echo Podfile >> .git/info/sparse-checkout")
    os.system("git remote rm origin")
    os.system("git remote add -f origin gitr:ee/lark/ios-client")
    os.chdir("../../")

    os.chdir("./python_rtc_symbolicate")
    os.system("git clone https://code.byted.org/weiyuning/test.git")
    os.chdir("../")


def updatePodfile(version):
    print("更新pod")
    os.chdir("./python_rtc_symbolicate/ios-client")
    os.system("git pull")
    os.system("git checkout "+version)
    f = open("Podfile", "r")
    lines = f.readlines()
    f.close()
    for line in lines:
        if "ByteRtcSDK" in line:
            break
    rtc_line = line
    os.chdir("../test")
    os.system("git clean -fxd")
    podfile = open("Podfile", "r")
    lines = podfile.readlines()
    podfile.close()
    for index, line in enumerate(lines):
        if "ByteRtcSDK" in line:
            lines[index] = rtc_line
            break

    podfile = open("Podfile", "w")
    podfile.write("".join(lines))
    podfile.close()
    try:
        os.system("pod install")
    except Exception:
        print("pod install")
    os.chdir("../../")


def analyLog(filename):
    now = os.getcwd()
    oldpath = "./python_rtc_symbolicate/"
    newpath = "./python_rtc_symbolicate/test/Pods/ByteRtcSDK/"
    shutil.copyfile(oldpath+filename, newpath+filename)
    shutil.copyfile(oldpath+"test/main.py", newpath+"main.py")
    os.chdir(newpath)
    os.system("python3 main.py")
    os.chdir(now)
    print(os.getcwd())

def uploadAttachment(issueKey, filename):
    print("上传解析日志")

    url = "https://jira.bytedance.com/rest/api/2/issue/" + issueKey + "/attachments"

    auth = HTTPBasicAuth("weiyuning", "Wwyn91355811")

    headers = {
        "Accept": "application/json",
        "X-Atlassian-Token": "no-check"
    }

    response = requests.request(
        "POST",
        url,
        headers=headers,
        auth=auth,
        files={'file': open('./python_rtc_symbolicate/test/Pods/ByteRtcSDK/'+filename, 'rb')}
    )

    print(response.text)

if __name__ == '__main__':
    name = sys.argv[1]
    if name == "init":
        firstRun()
    else:
        attachment_url = getAttachmentUrl(name)
        version, filename = getAttachment(attachment_url)
        updatePodfile(version)
        analyLog(filename)
        uploadAttachment(name, filename.split(".")[0]+".new.txt")


