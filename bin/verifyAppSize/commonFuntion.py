# from tos import TosClient
import hashlib
import os
import requests
import time
import json

GET_BASELINE = "https://cloudapi.bytedance.net/faas/services/tt8016lbw9cz846a28/invoke/get_last_base_line_info/"
SET_BASELINE = "https://cloudapi.bytedance.net/faas/services/tt8016lbw9cz846a28/invoke/set_current_base_line_info"
LIGHT_SERVICE_HOST = "https://cloudapi.bytedance.net/faas/services/tt4446x260a16e6e03/invoke/appsize_notify"
SUMBMIT_CHECK_VERIFY = "https://cloudapi.bytedance.net/faas/services/tt8016lbw9cz846a28/invoke/ios-client_submit_check"
CURRENT_VERSION_FAIL_BIZS = "https://cloudapi.bytedance.net/faas/services/tt8016lbw9cz846a28/invoke/ios-client-current-bizs-fail"
UPDATE_FAIL_BIZS = "https://cloudapi.bytedance.net/faas/services/tt8016lbw9cz846a28/invoke/ios-client_submit_check_update"
NEST_HOST = "https://nest.bytedance.net/api/v1/lark_data/projects/3"
BIA_OWNER = "https://seer.bytedance.net/api/m150/dashboard/bizline_owner?product=Lark&platform=iOS"
USER_INFO = "https://fsopen.feishu.cn/open-apis/user/v4/email2id"
COMMIT_LINES_INFO = "https://cloudapi.bytedance.net/faas/services/tt8016lbw9cz846a28/invoke/get_code_lines"
UPDATE_COMMIT_LINES_INFO = "https://cloudapi.bytedance.net/faas/services/tt8016lbw9cz846a28/invoke/udpate_code_lines"
aeolus_daily_report_HOST = "https://cloudapi.bytedance.net/faas/services/ttm4gl/invoke/newCIPkgSize"
aeolus_appstore_HOST = "https://cloudapi.bytedance.net/faas/services/ttm4gl/invoke/newPkgSize"


GERRIT_HOST = "https://review.byted.org"
PK150_HOST = 'https://seer.bytedance.net/api/m150'

bucket = 'lark-ios'
PK150_FUNC_NAME_CREATE_TASK = 'tasks/create'
PK150_FUNC_NAME_QUOTA_INFO = 'info/issues'
PK150_FUNC_NAME_TASK_STATUS = 'tasks/status'
PACKAGE_INFO_URL_PATH = "info/package"
BUSSINESS_LINE_INFO = "info/issues"
FIND_BIZ = "bizline/batch_find"

# 轻应用
APP_ID = "cli_9dfb6ce825eb1102"
APP_SECRET = "yMAxUXAsd8UbK8sKjOHfvcslKKZ1A4tw"
BOT_HOST = "https://fsopen.feishu.cn/open-apis/message/v4/send/"

parent_dir = os.path.dirname(__file__)

# 轮询间隔
POLL_INTERVAL = 2

def log(content):
    print("[--------Log]: " + content)

# 获取文件md5
def get_file_md5(filename):
    if not os.path.isfile(filename):
        return
    myHash = hashlib.md5()
    f = open(filename,'rb')
    while True:
        b = f.read(8096)
        if not b:
            break
        myHash.update(b)
    f.close()
    return myHash.hexdigest()

def getBusinessLineInfo(task_id):
    business_line_url = PK150_HOST + "/" + BUSSINESS_LINE_INFO
    headers = {
        'Content-Type': 'application/json'
    }
    package_info_param = {"task_id": task_id}
    r = requests.get(business_line_url, params=package_info_param, headers = headers)
    rep_dict = r.json()
    if not (r.ok and rep_dict["success"]):
        return
    result = rep_dict["result"]
    passed_list = result["passed"]["bizline_quota"]
    fail_list = []
    if "failed" in result.keys():
        fail_list = result["failed"]["bizline_quota"]
    list = passed_list + fail_list
    dict = {}
    for item in list:
        name = item["verbose_name"]
        dict[name] = item
    return dict

def getStrAsMD5(parmStr):
    if isinstance(parmStr,str):
        # 如果是unicode先转utf-8
        parmStr=parmStr.encode("utf-8")
    m = hashlib.md5()
    m.update(parmStr)
    return m.hexdigest()

# 上传url文件到tos
# 上传url文件到tos
# def upload_file_url(file_url, file_name):
#     access_key = 'RQHT0LLK2IFV7CAMCX01'
#     return upload_file_url_core(bucket, access_key, file_url, file_name)

def upload_file_url_core(file_url, file_name):
    print("upload_file_url_core url : {}".format(file_url))
    headers = {'Authorization': 'Basic eWFvcWloYW86MTE1ZDRkODAyMDRlMDQ0YzQ3YzI4YWFkNzM3ZWJhZDdhOQ=='}
    r = requests.get(file_url, headers=headers)
    if r.status_code == 200:
        file_path = os.path.join(parent_dir, "temp")
        with open(file_path, "wb") as f:
            f.write(r.content)
        upload_local_file_url(file_path, file_name)
        os.system("rm -f {}".format(file_name))
        return "https://voffline.byted.org/download/tos/schedule/" + bucket + "/" + file_name
    else:
        raise Exception("文件下载失败，code:" + str(r.status_code) + " content:\n" + r.text)


def upload_file_url(file_path, file_name):
    return upload_file_url_core(file_path, file_name)

def upload_local_file_url(file_path, file_name):
    bucket = 'lark-ios'
    if not os.path.exists("/usr/local/bin/tos-upload"):
        # 安装上传tos工具
        os.system("curl http://tosv.byted.org/obj/toutiao.ios.arch/tos_uploader/install.sh | sh")
    command = "tos-upload -b {} -k {} {}".format(bucket, file_name, file_path)
    shell_result = os.popen(command).read()
    if "success" not in shell_result:
        raise Exception("上传ipa失败:{}".format(shell_result))
    return "https://voffline.byted.org/download/tos/schedule/" + bucket + "/" + file_name


def create_task(params):
    create_mr_url = PK150_HOST + "/" + PK150_FUNC_NAME_CREATE_TASK
    headers = {
        'Content-Type': 'application/json'
    }
    res = requests.post(url=create_mr_url, json=params, headers=headers)
    print("create_task返回值{}",format(res.text))
    if res.status_code == requests.codes.ok and res.json()["success"] == 1:
        pass
    return res.json()["result"]["task_id"]

# 轮询查询结果
def poll(task_id):
    log("轮询进行中")
    if len(task_id) < 1:
        log("异常退出，task_id为空")
        exit(1)
    res = requests.get(PK150_HOST + "/" + PK150_FUNC_NAME_TASK_STATUS, params={"task_id": task_id})

    status = res.json()["result"]["status"]
    log("status: " + status)
    if status == "success":
        log("平台解析完成")
        return True
    elif status == "failed":
        return False
        # raise Exception("任务" + PK150_FUNC_NAME_TASK_STATUS + "失败， content:\n" + res.text)
    else:
        # 平台已经开始分析，但是还没有结果，递归调用，直到分析结束
        time.sleep(POLL_INTERVAL)
        return poll(task_id)

# 发送机器人消息
def sendBotMsg(webHook, title, text):
    headers = {
        'Content-Type': 'application/json'
    }
    params = {
        'title': title,
        'text': text
    }
    res = requests.post(url=webHook, headers=headers, json=params)
    return res.ok and res.json()["ok"]

# 根据task_id获取安装包thinned size
def getPackageThinnedSize(task_id):
    package_info_url = PK150_HOST + "/" + PACKAGE_INFO_URL_PATH
    package_info_param = {"task_id": task_id}
    r = requests.get(package_info_url, params=package_info_param)
    result = r.json()
    return result["result"]["standard_size"]


# 获取上一版本的包体积信息
def getLastBaseLinePackageThinnedInfo(currentVersion, type):
    r = requests.get(GET_BASELINE, params={"current_version": currentVersion, "type": type})
    result = r.json()
    version = result['version']
    task_id = result['task_id']
    return getPackageThinnedSize(task_id), version, task_id


def get_tenant_access_token(app_id, app_secret):
    param = {
        "app_id": app_id,
        "app_secret": app_secret
    }
    headers = {
        'Content-Type': 'application/json'
    }
    response = requests.post("https://fsopen.feishu.cn/open-apis/auth/v3/tenant_access_token/internal/", headers=headers, json=param)
    token = response.json()["tenant_access_token"]
    return token

def sendBot(body):
    tenet_id = get_tenant_access_token(APP_ID, APP_SECRET)
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + tenet_id
    }
    response = requests.request("POST", BOT_HOST, headers=headers, json=body)
    print("机器人接口返回值：{}".format(response.content))


def sendFailMsg(chatID):
    msgBody = {
        "chat_id": chatID,
        "msg_type": "post",

        "content": {
            "post": {
                "zh_cn": {
                    "content": [
                        [
                            {
                                "tag": "at",
                                "user_id": "6716305595533639949"
                            },
                            {
                                "tag": "text",
                                "text": "触发iOS-client master分支配额检测失败了❌❌，"
                            },
                            {
                                "tag": "a",
                                "text": "可以点我查看原因",
                                "href": "https://ee.byted.org/ci/view/Lark/job/lark/job/ios/job/app-analyse/job/ios-client-master-appsize-verify/"
                            }
                        ]
                    ]
                }
            }
        }
    }
    sendBot(msgBody)


def postCodeReview(changeID, msg, score):
    # 废弃方法
    return
    """
    codeReview  并附上信息
    :param changeID: changeID
    :param msg: 信息
    :return: 是否成功
    """
    if not add_reviewer(changeID):
        print("添加reviewer失败")
        return False

    url = "{}/a/changes/{}/revisions/current/review".format(GERRIT_HOST, changeID)
    param = {
        "labels": {
            "Code-Review": score
        }
    }
    if len(msg):
        param["message"] = msg

    headers = {
        'charset': 'utf-8',
        'Authorization': 'Basic aHVhbmdqaWFubWluZzpPSEo0dTRpckp1L2J1cDdCdXJxK2JBRWZDNWMxQnJxdURHYW8rMG52Qnc=',
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", url, headers=headers, json=param)
    return response.ok


def biz_owner():
    """
    业务线负责人
    :return: {biz_id: email}
    """
    reponse = requests.get(BIA_OWNER)
    result = reponse.json()
    list = result["result"]["bizlines"]
    retDict = {}
    for item in list:
        owners = item["owners"]
        if len(owners) > 0:
            email = owners[0]["email"]
            retDict[item["id"]] = email
    return retDict


def getUserOpenIDInfo(email):
    tenet_id = get_tenant_access_token(APP_ID, APP_SECRET)
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + tenet_id
    }
    params = {
        "email": email
    }
    reponse = requests.post(USER_INFO,json=params,headers=headers)
    return reponse.json()["data"]["open_id"]


def __check_install():
    """
    安装jscpd
    :return:
    """
    os.system('''
    if !(which jscpd >/dev/null); then
	    npm install jscpd -g	
    fi
    ''')


def __uploadDeplicateHtmlHtml(html_dir):
    """
    上传html文件到轻服务
    :param html_dir: 放置html的目录，需要有index.html
    :return:
    """
    parent_dir = os.path.dirname(__file__)
    shell_path = os.path.join(parent_dir, "deployDeplicateHtml.sh")
    os.system("sh {} {}".format(shell_path, html_dir))

def uploadUnusedHtmlHtml(used_dir):
    """
    上传html文件到轻服务
    :param html_dir: 放置html的目录，需要有index.html
    :return:
    """
    current_cwd = os.getcwd()
    os.chdir(used_dir)
    parent_dir = os.path.dirname(__file__)
    shell_path = os.path.join(parent_dir, "deployUnusedHtml.sh")
    os.system("sh {} {}".format(shell_path, "./"))
    os.chdir(current_cwd)

def uploadUnusedPNGHtml(used_dir):
    """
    上传html文件到轻服务
    :param html_dir: 放置html的目录，需要有index.html
    :return:
    """
    current_cwd = os.getcwd()
    os.chdir(used_dir)
    parent_dir = os.path.dirname(__file__)
    shell_path = os.path.join(parent_dir, "deploy_unused_png_html.sh")
    os.system("sh {} {}".format(shell_path, "./"))
    os.chdir(current_cwd)


def upload_unused_localization_html(used_dir):
    """
    上传html文件到轻服务
    :param html_dir: 放置html的目录，需要有index.html
    :return:
    """
    current_cwd = os.getcwd()
    os.chdir(used_dir)
    parent_dir = os.path.dirname(__file__)
    shell_path = os.path.join(parent_dir, "deployUnused_localization_html.sh")
    os.system("sh {} {}".format(shell_path, "./"))
    os.chdir(current_cwd)


def getDuplicateCodeData(pro_dir):
    """
    获取工程重复密码，并上传html文件到轻服务
    :param pro_dir: 需要扫描的工程
    :return: 统计数据
    """
    if not os.path.isdir(pro_dir):
        print("非法目录")
        return
    current_cwd = os.getcwd()
    os.chdir(pro_dir)

    output_dir = "./DuplicateCode"
    os.system("rm -rf {};mkdir {}".format(output_dir, output_dir))

    __check_install()
    os.system("jscpd --min-lines 40 -r json,html -o {} --formats-exts swift:swift -m weak -b --ignore './Libs/LarkNotificationServiceExtensionLib/src/*.swift'  ./".format(output_dir))

    # 重命名html文件为index.html
    html_path = os.path.join(output_dir, "jscpd-report.html")
    rename_html_path = os.path.join(output_dir, "index.html")
    os.system("mv {} {}".format(html_path, rename_html_path))

    __uploadDeplicateHtmlHtml(output_dir)

    json_path = os.path.join(output_dir, "jscpd-report.json")
    if not os.path.exists(json_path):
        print("没有生成jscpd-report.json文件")
        return
    f = open(json_path, encoding='utf-8')
    setting = json.load(f)
    os.chdir(current_cwd)
    return setting["statistics"]["total"]

def change_line_number(dir):
    current_line_info = os.popen("cloc {} --include-lang='Objective C,Swift'".format(dir)).read()
    print(current_line_info)
    lines = current_line_info.split("\n")

    __current_swift_line_number = 0
    __current_oc_line_number = 0
    for line in lines:
        if "Swift" in line:
            list = line.split()
            __current_swift_line_number = int(list[4])

        if "Objective C" in line:
            list = line.split()
            __current_oc_line_number = int(list[5])
    return (__current_swift_line_number, __current_oc_line_number)


def post_change_line_numbers(proj_dir):
    """
    向gerrit发送代码行数变更,内部会自动更新commit—id的数据
    :param proj_dir:
    :param changeID:
    :return: 无返回值
    """
    current_cwd = os.getcwd()
    os.chdir(proj_dir)

    # 当前commit id
    current_commit = os.popen("git rev-parse HEAD").read()

    # 上一次提交的commit id
    last_commit = os.popen("git rev-parse HEAD~").read()
    current_commit = current_commit.replace("\n", "")
    last_commit = last_commit.replace("\n", "")

    if not os.path.exists("/usr/local/bin/cloc"):
        os.system("brew install cloc")

    bizs_line_number = change_line_number(os.path.join(proj_dir, "Bizs"))
    pods_line_number = change_line_number(os.path.join(proj_dir, "Pods"))
    libs_line_number = change_line_number(os.path.join(proj_dir, "Libs"))

    __current_swift_line_number = bizs_line_number[0] + pods_line_number[0] + libs_line_number[0]
    __current_oc_line_number = bizs_line_number[1] + pods_line_number[1] + libs_line_number[1]

    print("__current_swift_line_number:{},__current_oc_line_number:{}".format(__current_swift_line_number,
                                                                              __current_oc_line_number))
    if __current_swift_line_number <= 0 or __current_oc_line_number <= 0:
        exit(0)

    # 更新轻服务commitid相关的代码行数
    __param = {
        "commit": current_commit,
        "swift":__current_swift_line_number,
        "oc": __current_oc_line_number
    }
    r = requests.get(UPDATE_COMMIT_LINES_INFO, params=__param)
    if r.json()["code"] == 0:
        print("更新commitID:{}成功".format(current_commit))
    else:
        print("更新commitID:{}失败".format(current_commit))

    param = {"commit": last_commit}
    r = requests.get(COMMIT_LINES_INFO, params=param)
    result = r.json()

    if result["code"] == 0:
        __last_swift_line_number = int(result["swift"])
        __last_oc_line_number = int(result["oc"])

        print("__last_swift_line_number:{},__last_oc_line_number:{}".format(__last_swift_line_number,
                                                                                  __last_oc_line_number))

        if __last_swift_line_number > 0 and __last_oc_line_number > 0:
            _swift_diff = __current_swift_line_number - __last_swift_line_number
            _oc_diff = __current_oc_line_number - __last_oc_line_number
            size_diff = float(_swift_diff + _oc_diff) / 10

            ceiling = round(size_diff * 1.2, 2)
            floor = round(size_diff * 0.8, 2)

            msg = "本次提交({})会导致iOS-client工程 新增swift代码:{}行,oc代码：{}行(不包含注释和空行), 预估代码导致的包体积增加：{}KB ~ {}KB(资源文件没计算在内)".format(current_commit, _swift_diff, _oc_diff, floor, ceiling)

            #大于10K时在发送消息
            if abs(size_diff) < 10:
                return

            sendBotMsg("https://fsopen.feishu.cn/open-apis/bot/hook/4290db362d404f06b8fb81eb122b083c","超限了", msg)
        else:
            print("没有检测到代码变更")
    else:
        print("{}请求失败".format(COMMIT_LINES_INFO))

    os.chdir(current_cwd)


def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        pass

    try:
        import unicodedata
        unicodedata.numeric(s)
        return True
    except (TypeError, ValueError):
        pass
    return False

