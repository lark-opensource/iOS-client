import hashlib
import os
import requests
import time
import json
import argparse

def get_tenant_access_token(app_id, app_secret):
    param = {
        "app_id": app_id,
        "app_secret": app_secret
    }
    headers = {
        'Content-Type': 'application/json'
    }
    response = requests.post("https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal/", headers=headers, json=param)
    token = response.json()["tenant_access_token"]
    return token

def sendBot(msg):
    tenet_id = get_tenant_access_token('cli_a0267520c4789013', 'B7fsgaiDRfN33AvynRl1ehzppdp1rRHF')
    print(tenet_id)
    headers = {
        'Content-Type': 'application/json',
        "cache-control": "no-cache",
        'Authorization': 'Bearer ' + tenet_id
    }
    param = {
        "msg_type": "text",
        "user_id": "6959373492382908443",
        "content": {
            "text": msg
        }
    }
    print(param)
    response = requests.request("POST", 'https://open.feishu.cn/open-apis/message/v4/send/', headers=headers, json=param)
    print("机器人接口返回值：{}".format(response.content))

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--botMsg')
    args = p.parse_args()
    bot_Msg = args.botMsg
    sendBot(bot_Msg)
