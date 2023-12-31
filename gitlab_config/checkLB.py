import os
import requests
from datetime import date
import json
import re

CONY_CALENDAR_URL = "https://cony.bytedance.net/api/calendar?space_alias=%20Lark%20App"  #Lark在cony上的日历接口

def isValid(lb_id):
    command = "curl 'https://nest.bytedance.net/api/v2/lb_issues/{}' \
  -H 'authority: nest.bytedance.net' \
  -H 'accept: application/json, text/plain, */*' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'referer: https://nest.bytedance.net/lark/lb' \
  -H 'accept-language: zh-CN,zh;q=0.9,en;q=0.8' \
  -H 'cookie: _ga=GA1.2.136039332.1570630327; nest-session=c5738273-106f-4bad-90fb-43138472818a; SLARDAR_WEB_ID=46475839-4b9c-4123-b553-083478529420; _hjid=c1a33cae-9c4a-458c-a71b-92439f4277ec; _hjTLDTest=1; _gid=GA1.2.1994226799.1606810149; _hjIncludedInPageviewSample=1; _hjAbsoluteSessionInProgress=0; _gat=1' \
  --compressed".format(lb_id)

    result = os.popen(command).read()
    result_dict = {}
    try:
        result_dict = json.loads(result)
    except:
        return False
    if result_dict["approval_status"] == "APPROVED":
        return True
    return False

if "CUSTOM_CI_COMMIT_TARGET_REF_NAME" in os.environ:
    target_branch = os.environ["CUSTOM_CI_COMMIT_TARGET_REF_NAME"]
    if target_branch.startswith("release/"):
        if "CI_COMMIT_REF_NAME" in os.environ:
            source_branch = os.environ["CI_COMMIT_REF_NAME"]
        elif "WORKFLOW_REPO_BRANCH" in os.environ:
            source_branch = os.environ["WORKFLOW_REPO_BRANCH"]
        else:
            raise Exception("无法获取到源分支")

        if not source_branch.startswith("bugfix/"):
            raise Exception("分支命名规范错误：合入release源分支名必须为bugfix/*开头")

        branch_version = target_branch.replace("release/", "").strip()
        print("版本：{}".format(branch_version))
        
        if branch_version < "3.36":
            if isValid(lb_id):
                print("3.36版本前，只要Lb满足即可")
                exit(0)
            else:
                raise Exception("LB不合法")

        # 获取封板状态
        r = requests.get(CONY_CALENDAR_URL)
        if r.ok:
            content_dict = r.json()
            events_list = []
            try:
                tracks = content_dict["successInfo"]["tracks"]
            except:
                print("数据异常")
            for track in tracks:
                events_list = track["events"]
                for version_dat in events_list:
                    if version_dat["name"] == branch_version:
                        segments = version_dat["segments"]
                        print(r.content)
                        for segment in segments:
                            if "飞书灰度" in segment["name"]:
                                # 灰度开始日期
                                date_str = segment["calc_endDate"]
                                today = date.today()
                                day = today.day
                                month = today.month
                                #为了方便比较，需要补0
                                if day<10:
                                    day = "0{}".format(day)
                                if month<10:
                                    month = "0{}".format(month)
                                current_date_str = "{}{}{}".format(today.year, month, day)
                                print("当前日期：{},飞书灰度结束日期:{}".format(current_date_str, date_str))
                                if current_date_str > date_str:
                                    # 表示当前为灰度版本之后，必须判断LB状态是否已经通过，否则不能通过
                                    if "LB_ID" in os.environ:
                                        lb_id = os.environ["LB_ID"]
                                        lb_id = re.findall('\d+', lb_id)[0]
                                        if isValid(lb_id):
                                            print("LB_id:{}合法".format(lb_id))
                                            exit(0)
                                    raise Exception("LB不合法或者没有指定LB_ID".format(lb_id))
                        break
    else:
        print("当前非release分支,不需要检查LB")
else:
    raise Exception("无法获取到目标分支")
