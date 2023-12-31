# -*- coding:utf-8 -*-
import hashlib
import os
import requests
import time
import json
import argparse

# 轮询查询结果
def poll(task_id):
    log("轮询进行中")
    if len(task_id) < 1:
        log("异常退出，task_id为空")
        exit(1)
    res = requests.get("https://seer.bytedance.net/api/m150" + "/" + "tasks/status", params={"task_id": task_id})

    status = res.json()["result"]["status"]
    log("status: " + status)
    if status == "success":
        log("平台解析完成")
        return 0
    elif status == "failed":
        raise Exception("任务" + PK150_FUNC_NAME_TASK_STATUS + "失败， content:\n" + res.text)
    else:
        # 平台已经开始分析，但是还没有结果，递归调用，直到分析结束
        time.sleep(POLL_INTERVAL)
        return poll(task_id)
    return -1

# 创建Pk150 任务
def create_task(params):
    #接口文档 https://bytedance.feishu.cn/docs/doccnyyV5gEc6s6ciLLJOwM3cza
    create_mr_url = "https://seer.bytedance.net/api/m150" + "/" + "tasks/create"
    headers = {
        'Content-Type': 'application/json'
    }
    res = requests.post(url=create_mr_url, json=params, headers=headers)
    print("create_task返回值{}",format(res.text))
    if res.status_code == requests.codes.ok and res.json()["success"] == 1:
        pass
    return res.json()["result"]["task_id"]

#发送信息到 MR
def sendTimelineMsg(mr_id: int, msg, level:str):
    url = "https://bits.bytedance.net/openapi/merge_request/timeline"
    param = {
        "mr_id": mr_id,
        "operator": "songlongbiao",
        "data": msg,
        "level": level
    }
    headers = {
        'Authorization': "Bearer 6575e63d766906bfac0ad94ee8345e62"
    }
    print(f"timeline请求返回数据{param}\n")
    resp = requests.post(url=url, json=param, headers=headers)
    print(f"timeline请求返回结果{resp.text}")
    if resp.ok:
        print("发送timeline请求成功")
    else:
        print("发送timeline请求失败")

#查询MR绑定的任务
def getRelatedTasks(mr_iid):
    res_dict = {
        "last_base_job_id":0,
        "last_job_id":1,
        "last_base_task_id":"",
        "last_task_id":"",

    }
    res = requests.get("https://seer.bytedance.net/api/m150" + "/" + "bits/mr/related_tasks", params={"project_id": "137801","mr_iid":mr_iid})
    print(res)
    if res.status_code == requests.codes.ok and res.json()["success"] == 1:
        related_tasks = res.json()["result"]["related_tasks"]
        for related_task in related_tasks:
            mr_job_id = int(related_task['mr_job_id']) - mr_iid
            # #如果是绑定MR对比的忽略
            # if mr_job_id > 1000:
            #     continue
            #判断是基线包还是测试包
            if mr_job_id%2 == 0 :
                if mr_job_id > res_dict["last_base_job_id"]:
                    res_dict["last_base_job_id"] = mr_job_id
                    res_dict["last_base_task_id"] = related_task['task_id']
            elif mr_job_id > res_dict["last_job_id"]:
                    res_dict["last_job_id"] = mr_job_id
                    res_dict["last_task_id"] = related_task['task_id']
    return res_dict

#绑定MR任务
def setMRTask(params):
    create_mr_url = "https://seer.bytedance.net/api/m150" + "/" + "mr/job"
    headers = {
        'Content-Type': 'application/json'
    }
    res = requests.post(url=create_mr_url, json=params, headers=headers)
    print("setMRTask返回值{}",format(res.text))
    # if res.status_code == requests.codes.ok and res.json()["success"] == 1:
    #     pass
    # return res.json()["result"]["task_id"]

#绑定MR任务
def upload_pk150_delay(params):
    upload_pk150_delay_url = "https://cloudapi.bytedance.net/faas/services/tt8016lbw9cz846a28/invoke/upload_pk150_delay"
    headers = {
        'Content-Type': 'application/json'
    }
    res = requests.post(url=upload_pk150_delay_url, json=params, headers=headers)
    print("upload_pk150_delay返回值{}",format(res.text))
    # if res.status_code == requests.codes.ok and res.json()["success"] == 1:
    #     pass
    # return res.json()["result"]["task_id"]

#python3 upload_pk150.py --ipaUrl https://voffline.byted.org/download/tos/schedule/iOSPackageBackUp/117254987/Lark_4.8.0-alpha-debug_14233693.ipa  --commitId 11b87424
# def test():
    # sendTimelineMsg(4070501, 'MR基准包大小:[PK150](https://pk150.bytedance.net/dashboard/task?task_id=lark-4-11-0-alpha-debug-18671966-e690a8ae)' , "success")
    # print(getRelatedTasks(4117050))
    # mr_param = {
    #     "product": "Lark",
    #     "platform": "iOS",
    #     "project_id": 137801,
    #     "mr_iid":4117050,
    #     #"affected_libs": ["TTIMSDK"], # MR 变更的库列表，没有的话不传
    #     "task_id":"lark-4-12-0-alpha-debug-20835126-36f0756dd0",
    #     #"base_task_id":"pk150-base-ab694915", # 基准任务，如果没有的话传不传
    #     "commit_id": str(4117050),
    #     "base_commit_id": "",
    #     "mr_job_id": 4117055, # MR pipeline 的 job id；job id 一般单调递增，可以在环境变量中取到，取不到的话也可以用时间戳代替
    # }
    # setMRTask(mr_param)

if __name__ == '__main__':
    # test()
    p = argparse.ArgumentParser()
    p.add_argument('--ipaUrl')
    p.add_argument('--commitId')
    #控制mr时输出类型
    p.add_argument('--uploadType')
    p.add_argument('--mrId')
    p.add_argument('--lastMrId')

    args = p.parse_args()
    ipaUrl = args.ipaUrl
    uploadType = args.uploadType
    commitId = args.commitId
    mrId = args.mrId
    lastMrId = args.lastMrId

    if mrId:
        params = {
            "ipaUrl": ipaUrl,
            "commitId": commitId,
            "uploadType": uploadType,
            "mrId": mrId,
            }
        if lastMrId:
            params["lastMrId"] = lastMrId
        upload_pk150_delay(params)
    # taskId =  ipaUrl.split('/')[-2]
    # lockfileUrl = 'https://voffline.byted.org/download/tos/schedule/iOSPackageBackUp/' + taskId + '/Podfile.lock'
    # linkmapUrl = 'https://voffline.byted.org/download/tos/schedule/iOSPackageBackUp/' + taskId + '/lark_link_map.txt'
    # version = ipaUrl.split('/')[-1].replace('.ipa','')

    # param = {"linkmaps": [linkmapUrl],
    #          "podfile_lock": lockfileUrl,
    #          "ipa": ipaUrl,
    #          "suggest_name": version,
    #          "configuration": "RELEASE",
    #          "product": "Lark",
    #          "commit_id": commitId
    #          }
    # task_id = create_task(param)
    # result_url = "https://pk150.bytedance.net/dashboard/task?task_id=" + task_id

    # if mrId:
    #     #发送timeline消息
    #     sendTimelineMsg(int(mrId), uploadType + ":[PK150]("+ result_url+")", "success")
    #     #区分基线包&测试包
    #     if os.environ.get("build_appsize_base"):
    #         os.environ['appsize_base_taskid'] = task_id
    #     else:
    #         os.environ['appsize_taskid'] = task_id

    #     related_tasks = getRelatedTasks(int(mrId))

    #     if uploadType == 'MR基准包大小':
    #         t = related_tasks['last_base_job_id'] + 2 + int(mrId)
    #         related_tasks['last_base_job_id'] = t
    #         related_tasks["last_base_task_id"] = task_id
    #     else:
    #         t = related_tasks['last_job_id'] + 2+ int(mrId)
    #         related_tasks['last_job_id'] = t
    #         related_tasks["last_task_id"] = task_id
    #     #兼容lastMrid 为空的情况
    #     if lastMrId == None:
    #         lastMrId = mrId

    #     #上传包信息至PK150
    #     mr_param = {
    #         "product": "Lark",
    #         "platform": "iOS",
    #         "project_id": 137801,
    #         "mr_iid":mrId,
    #         #"affected_libs": ["TTIMSDK"], # MR 变更的库列表，没有的话不传
    #         "task_id": task_id,
    #         #"base_task_id":"pk150-base-ab694915", # 基准任务，如果没有的话传不传
    #         "commit_id": str(mrId),
    #         "base_commit_id": str(lastMrId),
    #         "mr_job_id": t, # MR pipeline 的 job id；job id 一般单调递增，可以在环境变量中取到，取不到的话也可以用时间戳代替
    #     }
    #     setMRTask(mr_param)

    #     #如果基准包和测试包都有数据 输出对比链接
    #     if related_tasks['last_base_job_id'] != 0 and related_tasks['last_job_id'] != 1:
    #         # compare_mr_param = {
    #         #     "product": "Lark",
    #         #     "platform": "iOS",
    #         #     "project_id": 137801,
    #         #     "mr_iid":mrId,
    #         #     #"affected_libs": ["TTIMSDK"], # MR 变更的库列表，没有的话不传
    #         #     "task_id": related_tasks['last_task_id'],
    #         #     "base_task_id":related_tasks['last_base_task_id'],
    #         #     "commit_id": mrId,
    #         #     "base_commit_id": lastMrId,
    #         #     "mr_job_id": t+1000, # MR pipeline 的 job id；job id 一般单调递增，可以在环境变量中取到，取不到的话也可以用时间戳代替
    #         # }
    #         # setMRTask(mr_param)
    #         result_url = "https://pk150.bytedance.net/dashboard/task?task_id=" + related_tasks['last_task_id'] + "&base_task_id=" +related_tasks['last_base_task_id']
    #         sendTimelineMsg(int(mrId), 'MR包大小变化情况' + ":[PK150]("+ result_url+")", "success")

    