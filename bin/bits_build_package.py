import os
import requests


build_channel = os.environ.get("BUILD_CHANNEL")
task_id = os.environ.get("TASK_ID")
workspace_path = os.environ.get("WORKSPACE")

print("打印参数：{}, {}, {},环境变量：{}".format(build_channel, task_id, workspace_path，os.environ))

# ret = os.system("bundle exec fastlane ios Lark build_channel:{} configuration:'Release' build_number:{} output_directory:{}/archives".format(build_channel, task_id, workspace_path))

# if not ret == 0:
#     print("执行失败，提前退出")
#     exit(1)

if "TASK_ID" in os.environ.keys():
    TASK_ID = os.environ["TASK_ID"]

    r = requests.get("https://gateway.byted.org/gw/v2/token", params={"email": "huangjianming@bytedance.com"})
    token = r.json().get("data").get("token")

    headers = {"Authorization": "Bearer " + token}

    r = requests.get("https://gateway.byted.org/gw/v2/tasks/result", headers=headers, params={"id": TASK_ID})
    content = r.json()
    print(content)
    artifacts_list = content.get("data").get("artifacts").get("artifacts")
    ipa_url = None

    if artifacts_list == None or len(artifacts_list) < 1:
        print("没有获取到产物")
        exit(1)

    for artifact in artifacts_list:
        if artifact.get("type") == "ipa":
            ipa_url = artifact.get("url")
            break
    if ipa_url == None:
        print("找不到ipa url")
        exit(1)

    project_id = os.environ.get("PROJECT_ID")
    mr_iid = os.environ.get("MR_IID")

    if project_id == None or mr_iid == None:
        print("没找对对应的project_id或者mr_iid")
        exit(0)

    commit_id = os.popen("git rev-parse HEAD").read()

    # 生成MR二维码
    json_param = {
        "project_id": project_id,
        "mr_iid": mr_iid,
        "commit_id": commit_id,
        "package_url": ipa_url,
        "package_name": "Lark-iOS"
    }

    requests.post("http://optimus.byted.org/api/v1/package/", json=json_param)

