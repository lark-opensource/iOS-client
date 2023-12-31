#!/usr/local/bin/python3
# coding: utf-8

import requests
import json
import sys
import os
import subprocess

def get_tenant_access_token():
    api = 'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal/'
    headers = {
        'Content-Type': 'application/json'
    }
    data = {
        "app_id": 'cli_9be17512bf721107',
        "app_secret": 'ydWj3QfJUunpAiRNrGl4abDEV2gHxvm1'
    }
    response = requests.post(api, headers=headers, json=data)
    body = json.loads(response.text)
    return str(body['tenant_access_token'])



def get_user_info_by(user_email, token):
    get_user_id_api = 'https://open.feishu.cn/open-apis/user/v1/batch_get_id'
    headers = {
        'Authorization': 'Bearer '+token,
        'Content-Type': 'application/json'
    }
    data = {
        "emails": user_email
    }
    # Lark 的 User ID 是根据 User Email 获取的
    response = requests.post(get_user_id_api, headers=headers, json=data)
    body = json.loads(response.text)
    if str(body["code"]) == '0':
        user_id = str(body['data']['email_users'][user_email][0]["user_id"])
    else:
        return None

    return user_id



def get_open_chat_id(token):
    api = 'https://open.feishu.cn/open-apis/exchange/v3/cid2ocid/'
    headers = {
        'Authorization': 'Bearer '+token,
        'Content-Type': 'application/json'
    }
    data = {
        "chat_id": '6592474326963752960'
    }
    response = requests.post(api, headers=headers, json=data)
    body = json.loads(response.text)
    open_chat_id = str(body['open_chat_id'])

    return open_chat_id


def send_lark(notification, token):
    postMessageApi = 'https://open.feishu.cn/open-apis/message/v4/send/'
    ocid = 'oc_3f6565418be5e78afd7e632b08da419a'
    headers = {
        'Authorization': 'Bearer '+token,
        'Content-Type': 'application/json'
    }
    data = {
        "chat_id": ocid,
        "msg_type": "forward",
        "content": notification
    }
    response = requests.post(postMessageApi, headers=headers, json=data)
    print(response)

if __name__ == '__main__':
    print('\nLARK-ROBOT-PUSH\n')
    tenant_access_token = get_tenant_access_token()

    illegal_revision_number = subprocess.getoutput('cat Modules/SpaceKit/Libs/SKResource/Resources/eesz-zip/current_revision | grep -e ^version')
    illegal_revision_number = illegal_revision_number.split(":")[1]

    commit_sha = subprocess.getoutput('git rev-parse --short HEAD')

    committer_email = subprocess.getoutput(f"git show -s --format='%ce' `git rev-parse HEAD`")
    committer_user_id = get_user_info_by(committer_email, tenant_access_token)
    at_link = f'<at user_id=\"{committer_user_id}\"></at>'

    notification = {
        "title": f"你的提交不合规，请及时处理",
        "text": f'<p>{at_link} 的提交 {commit_sha} 包含了前端资源包（版本：{illegal_revision_number}），它不是精简包，不允许合入主分支。请重新提交精简包。</p>'
    }

    send_lark(notification, tenant_access_token)