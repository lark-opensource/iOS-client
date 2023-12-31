import glob
import os
import requests
from requests_toolbelt.multipart.encoder import MultipartEncoder

def post_bot_message(name, url):
    bot_url = 'https://open.feishu.cn/open-apis/bot/v2/hook/427133a5-5ef0-40ad-ab51-2a29779df675'
    title = "[Gadget Demo]最新的 alpha 包({})已构建成功".format(name)
    post_body = {
        "msg_type": "post",
        "content": {
            "post": {
                "zh_cn": {
                    "title": title,
                    "content": [
                        [{
                            'tag': 'text',
                            'text': 'ipa 下载地址: {}'.format(url)
                        }]
                    ]
                }
            }
        }
    } 
    r = requests.post(bot_url, json=post_body)
    r.raise_for_status()

def upload_file():
    files = glob.glob('archives/*.ipa')
    if len(files) != 1:
        print('%d ipa found! should have unique one!' % (len(files)))
        return
    path = files[0]
    _, name = os.path.split(path)
    multipart_data = MultipartEncoder(
        fields={
            'os': 'ios',
            'uploadTosFile': (name, open(path, 'rb'), 'text/plain')
        }
    )
    response = requests.post('https://gadgetcare.byted.org/archive/upload', data=multipart_data,
                  headers={'Content-Type': multipart_data.content_type})
    if response.status_code == 200:
        key = response.json()['key']
        url = 'http://tosv.byted.org/obj/lark-gadget/{}'.format(key)
        post_bot_message(name, url)
        print('upload success, download link: {}'.format(url))
    else:
        print('ERROR!! upload fail, response={}', response)
        exit(1)

upload_file()

