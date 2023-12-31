import sys
import requests
import json
import shutil
import argparse
import ssl
import urllib
import os
import base64
import hashlib
import zipfile
import time

COUNT = 3
while COUNT:
    try:
        import pycryptodome
        print("pycryptodome模块已安装")
        break
    except:
        print("安装pycryptodemo中......")
        os.system("pip3 install pycryptodome")
        COUNT -= 1
        continue
from Crypto.Cipher import AES
from distutils.version import StrictVersion

# GitLab API访问凭证
GITLAB_TOKEN = "AHyzBb-XrRxZbHwzLJy7"
ODR_URL = "https://api-interanl-package.bytedance.net/internal-apis/mina/v2/internal_odr_get_app_meta"
AppExtension_URL = 'https://api-interanl-package.bytedance.net/internal-apis/mina/InternalOdrAppExtensionMeta'

FEISHU_CHANNEL = "Feishu"
LARK_CHANNEL = "Lark"

def get_ka_tenant_list_and_nationality(channel, version):
    info_url = f"https://cloudapi.bytedance.net/faas/services/tttswszxlemb2szaz8/invoke/getKAClientBuildData?channel={channel}&platform=ios&version={version}"
    response = requests.get(info_url)
    response_json = json.loads(response.text)
    tenant_id_list = response_json["data"]["tenant_ids"]
    nationality = response_json["data"]["client_build_env"]["BUILD_PRODUCT_TYPE"]
    return tenant_id_list, nationality

def get_tenant_list(channel, version):
    # 飞书科技有限公司租户id: 7104575615927599106; Lark Technologies: 6679695762999214345
    if channel == FEISHU_CHANNEL:
        tenant_id_list = ["6678657310388240652"]
    elif channel == LARK_CHANNEL:
        tenant_id_list = ['6679695762999214345']
    else:
        _, ka_nationality = get_ka_tenant_list_and_nationality(channel, version)
        tenant_id_list = ["6678657310388240652"] if ka_nationality == "KA" else ['6679695762999214345']
    return tenant_id_list


def get_appid_list(channel, branch, ka_nationality):
    if channel == "Feishu" or channel == "Lark":
        api_url = f"https://code.byted.org/lark/Lark_ODR/raw/{branch}/SaaS/{channel}/appIds.txt?inline=false"
    else:
        api_url = f"https://code.byted.org/lark/Lark_ODR/raw/{branch}/KA/{channel}/appIds.txt?inline=false"
    headers = {
        "PRIVATE-TOKEN": GITLAB_TOKEN
    }
    response = requests.get(api_url, headers=headers)
    if response.status_code == 200:
        return str(response.content).lstrip("'b").rstrip("'").split('\\n')
    else:
    # 兜底逻辑，使用master分支的数据作为兜底，KA内Lark中配置为海外KA兜底名单，还请求不到则报错
        print(f"❌❌❌原分支中channel数据的appIds.txt请求失败，使用master分支的兜底逻辑！")
        if channel == "Feishu" or channel == "Lark":
            temp_url = f"https://code.byted.org/lark/Lark_ODR/raw/master/SaaS/{channel}/appIds.txt?inline=false"
        else:
            if ka_nationality == "KA":
                temp_url = f"https://code.byted.org/lark/Lark_ODR/raw/master/KA/appIds.txt?inline=false"
            elif ka_nationality == "KA_international":
                temp_url = f"https://code.byted.org/lark/Lark_ODR/raw/master/KA/Lark/appIds.txt?inline=false"
            else:
                print("❌❌❌KA配置中的BUILD_PRODUCT_TYPE非法，请检测配置！")
                exit(-1)
        temp_response = requests.get(temp_url, headers=headers)
        if temp_response.status_code == 200:
            return str(temp_response.content).lstrip("'b").rstrip("'").split('\\n')
        else:
            print("❌❌❌master分支的兜底appId.txt逻辑配置错误，请检测配置！")
            exit(-1)

def get_block_list(channel, branch, ka_nationality):
    if channel == "Feishu" or channel == "Lark":
        api_url = f"https://code.byted.org/lark/Lark_ODR/raw/{branch}/SaaS/{channel}/blockIds.txt?inline=false"
    else:
        api_url = f"https://code.byted.org/lark/Lark_ODR/raw/{branch}/KA/{channel}/blockIds.txt?inline=false"
    headers = {
        "PRIVATE-TOKEN": GITLAB_TOKEN
    }
    response = requests.get(api_url, headers=headers)
    if response.status_code == 200:
        block_list = str(response.content).lstrip("'b").rstrip("'").split('\\n')
        block_list[0] = 'b' + block_list[0]
        return block_list
    else:
    # 兜底逻辑，使用master分支的数据作为兜底，还请求不到则报错
        print(f"❌❌❌原分支中channel数据的blockIds.txt请求失败，使用master分支的兜底逻辑！")
        if channel == "Feishu" or channel == "Lark":
            temp_url = f"https://code.byted.org/lark/Lark_ODR/raw/master/SaaS/{channel}/blockIds.txt?inline=false"
        else:
            if ka_nationality == "KA":
                temp_url = f"https://code.byted.org/lark/Lark_ODR/raw/master/KA/blockIds.txt?inline=false"
            elif ka_nationality == "KA_international":
                temp_url = f"https://code.byted.org/lark/Lark_ODR/raw/master/KA/Lark/blockIds.txt?inline=false"
            else:
                print("❌❌❌KA配置中的BUILD_PRODUCT_TYPE非法，请检测配置！")
                exit(-1)
        temp_response = requests.get(temp_url, headers=headers)
        if temp_response.status_code == 200:
            block_list = str(temp_response.content).lstrip("'b").rstrip("'").split('\\n')
            block_list[0] = 'b' + block_list[0]
            print(block_list)
            return block_list
        else:
            print("❌❌❌master分支的兜底blockId.txt逻辑配置错误，请检测配置！")
            exit(-1)

def get_low_version_miniapp(tenant_id, version, id, language, type):
    result_list = []
    original_result_list = []
    if type == "mini_app":
        meta_data = fetchMetaData(version, tenant_id, id, language)
        result_list.append(meta_data)
        original_result_list.append(meta_data)
    elif type == "app_extension":
        meta_data_original = featchBlockData(tenant_id, language, id)
        meta_data = meta_data_original['data']
        result_list.append(meta_data)
        original_result_list.append(meta_data_original)
    return result_list[0], original_result_list[0]

# 小程序和app_extension语言
def get_language(channel):
    if channel == "Lark":
        language = "en"
    else:
        language = "zh_CN"
    return language

def decrypt(text):
    key = "B4huRIrpmThGgYiY"
    iv = "tfQ2Sw04GMEdwUy4"
    mode = AES.MODE_CBC
    encry_text = base64.b64decode(text)
    cryptor = AES.new(key.encode(), mode, iv.encode())
    plain_text = cryptor.decrypt(encry_text)
    return plain_text.decode().rstrip('')

def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def generatedRequestID():
    t = time.time()  # 当前时间
    currentSecondInMiles = int(round(t * 1000))
    return '02'+str(currentSecondInMiles)+'e8eb8ee96d48128a140ae449377fd6dfeqbbbb'

def fetchMetaData(version, tenant_id, app_id, language):
    requestID = generatedRequestID()
    print(f"Start fetch Meta Data, app_id: {app_id}, requestID:{requestID}, tenant_id:{tenant_id}")
    headers = {'content-type': 'application/json',
               'x-tt-env': 'canary',
               'Authorization': 'Basic bGlhbmd6ZXh1OjEyMzQ1Nmw=',
               'x-request-id': requestID,
               'x-tt-logid': requestID}
    body = {
        "tenant_id": tenant_id,
        "user_id": 7106113069863927828,
        "device_id": 1,
        "app_id": app_id,
        "version": "current",
        "ttcode": "tYpQQypn9ni1%2FPqZj4U6mRCh8IrwyGdvvYfgM8XlXu7WQu532IzmYCSF8KNx1TRs%2FwnsOjeh%2FH%2FstFoO8sJqRO2lPrbmxQIXgoB8uaqxwXvSa%2BzlsGlRAw79ys%2FkPmL%2FPL4eBHyb8MZova4ceUvdq17uD5JfwpyEJL56%2B%2BmlTXU%3D",
        "language": language,
        "app_version": version,
        "platform": "ios",
        "token": "dabd09d7-cdbb-4652-92c0-5aa42e610c6b"
        }
    response = requests.post(ODR_URL, json=body, headers = headers)
    print("Meta Download Info: " + response.text)
    return response.json()["data"]

def featchBlockData(tenant_id, language, extension_id):
    requestID = generatedRequestID()
    print(f"Start fetch Block Data, entension_id: {extension_id}, requestID:{requestID}")
    headers = { 'accept': '*/*',
                'accept-language': 'zh-CN',
                'content-type': 'text/plain;charset=utf-8',
                'accept-encoding': 'gzip',
                'x-request-id': requestID,
                'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
                'x-tt-logid': requestID,
               }
    body = {
        "tenant_id": tenant_id,
        "user_id": 7106113069863927828,
        "token": "dabd09d7-cdbb-4652-92c0-5aa42e610c6b",
        # 最低客户端兼容版本。格式：x.xx.xx
        "app_queries": [{"extension_queries": {"extension_id": extension_id, "extension_type": "block"}}],
        "lang": language
    }
    response = requests.post(AppExtension_URL, json=body, headers=headers)
    print("Block Download Info: " + response.text)
    return response.json()

def dispose_block_response(meta):
    pkg_string = meta["app_metas"][0]['extension_metas'][0]["meta"]
    pkg_json = json.loads(pkg_string)
    return pkg_json

def decrypt_odr_package(meta, file_name, count):
    decryptedMD5 = decrypt(meta["md5"]).strip()
    fileMD5 = md5(file_name)
    if decryptedMD5.startswith(fileMD5):
        count += 1
        print("✅ package file check successfully:" + file_name)
    else:
        print("❌❌❌ ERROR: please check file md5 by yourself.")
        print("decrypted md5:" + decryptedMD5)
        print("package file md5:" + decryptedMD5)
        exit(-1)

def zip_odr_package(file_name, app_id):
    print("begin to compress file to zip")
    zipFileName = (str.encode('%s.zip' % (app_id), 'utf-8')).decode()
    zip = zipfile.ZipFile(zipFileName, "w", zipfile.ZIP_DEFLATED)
    zip.write(file_name)
    zip.close()
    os.remove(file_name)

def get_appid_and_package(type, meta):
    if type == "mini_app":
        packageURL = str(meta["path"][0])
        appId = meta["appid"].rstrip()
    elif type == "app_extension":
        pkg_string = meta["app_metas"][0]['extension_metas'][0]["meta"]
        pkg_json = json.loads(pkg_string)
        packageURL = pkg_json["pkg"]["block_mobile_lynx_pkg"]["url"]
        appId = meta["app_metas"][0]['extension_metas'][0]["extension_id"]
    return packageURL, appId

def download_odr(meta_list, odr_list, type):
    count = 0
    for meta in meta_list:
        packageURL, appId = get_appid_and_package(type, meta)
        if type == "mini_app":
            fileName = (str.encode('%s.pkg' % (appId), 'utf-8')).decode()
        elif type == "app_extension":
            fileName = (str.encode('%s.zip' % (appId), 'utf-8')).decode()
        print("packageURL: " + packageURL)
        print("fileName: " + fileName)
        context = ssl._create_unverified_context()
        packageData = urllib.request.urlopen(packageURL, context=context).read()
        packageFile = open(fileName, 'wb')
        packageFile.write(packageData)
        packageFile.close()
        if type == "mini_app":
            decrypt_odr_package(meta, fileName, count)
            zip_odr_package(fileName, appId)
        elif type == "app_extension":
            pkg_json = dispose_block_response(meta)
            block_md5 = pkg_json["pkg"]["block_mobile_lynx_pkg"]["md5"]
            if md5(fileName) != block_md5:
                print(f"❌❌❌{packageFile} md5校验失败！")
                exit(-1)
        count += 1
    if count == len(odr_list):
        print("✅✅✅ CONGRATULATIONS: all preset packages download successfully")
    else:
        print("❌❌❌ ATTENTION: packages download with error, please check log carefully!")
        exit(-1)


def move_files(source_folder, destination_folder):
    # 遍历源文件夹中的文件
    for filename in os.listdir(source_folder):
        # 检查文件名是否以"cli"或"blk"开头，并且以".zip"为后缀
        if filename.startswith(("cli_", "blk_")) and filename.endswith(".zip"):
            # 构建源文件路径和目标文件路径
            source_path = os.path.join(source_folder, filename)
            destination_path = os.path.join(destination_folder, filename)
            # 移动文件到目标路径
            shutil.move(source_path, destination_path)
            print(f"Moved file: {filename}")

# 向KA交付平台上报错误码
def get_auth_token(token_url):
    payload = json.dumps({
        "appid": "1DVmpp",
        "secret": "M5dQaVPFNF_wv0jfgO-iCkwkaR5GQqDj"
    })

    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.post(token_url, headers=headers, data=payload)
    if response.ok:
        response_info = response.json()
        access_token = response_info["access_token"]
        print(access_token)
        return access_token
    else:
        print("开放平台token请求失败！")

def post_error_msg(url, job_id, auth, error_code, error_msg):
    header = {
        'Authorization': auth,
        'Content-Type': 'application/json; charset=utf-8',
    }

    body = {
    "job_id": job_id,
    "status": 3,
    "error_info": {
        "error_code": error_code,
        "error_platform": "iOS",
        "error_msg": error_msg
        },
    "package_list":[]
    }

    response = requests.post(url, headers=header, data=json.dumps(body))
    print(response.text)
    print(response.headers)
    if response.ok:
        print("错误码上报成功")

def basic_auth(app_id: str, access_token: str) -> str:
    print("INFO: generate basic auth for app {}".format(app_id))
    auth = app_id + ":" + access_token
    return "Basic " + base64.b64encode(auth.encode()).decode()


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    # channel: 飞书：Feishu, Lark：Lark，KA: KA_CHANNEL
    p.add_argument('--channel')
    # version: 拉取release分支所需的odr
    p.add_argument('--version')
    # odr存储path
    p.add_argument('--output_path')
    args = p.parse_args()
    # 入参的channel, version和最终输出的path
    channel, input_version, output_path = args.channel, args.version, args.output_path
    def main():
        language = get_language(channel)
        version_list = input_version.split("-")[0].split(".")
        major_version, minor_version = version_list[0], version_list[1]
        version = major_version + "." + minor_version + ".0"
        branch = "release/" + version
        metaList = []
        blockList = []
        originalBlockList = []
        if channel != "Feishu" and channel != "Lark":
            _, ka_nationality = get_ka_tenant_list_and_nationality(channel, version)
        else:
            ka_nationality = "NO_KA_TYPE"
        tenant_id = get_tenant_list(channel, version)[0]
        print("获取app_id_text")
        app_id_list = get_appid_list(channel, branch, ka_nationality)
        print("获取block_id_text")
        block_id_list = get_block_list(channel, branch, ka_nationality)
        for app_id in app_id_list:
            miniapp_data = get_low_version_miniapp(tenant_id, version, app_id, language, "mini_app")[0]
            metaList.append(miniapp_data)
        for block_id in block_id_list:
            block_data, original_block_data = get_low_version_miniapp(tenant_id, version, block_id, language, "app_extension")
            blockList.append(block_data)
            originalBlockList.append(original_block_data)
        if len(app_id_list) != len(metaList):
            print("❌❌❌ERROR:data count not match, fatal error")
            exit(-1)
        with open(output_path + '/appMetaList.json', 'w') as outfile:
            json.dump(metaList, outfile)
        with open(output_path + '/blockMetaList.json', 'w') as outfile:
            json.dump(originalBlockList, outfile)
        download_odr(metaList, app_id_list, "mini_app")
        download_odr(blockList, block_id_list, "app_extension")
        odr_zip_path = os.path.abspath(os.path.dirname(os.path.dirname((__file__))))
        print(odr_zip_path)
        move_files(odr_zip_path, output_path)
    try:
        main()
    except Exception as e:
        print(f"❌❌❌ ERROR: Fetch ODR Script has error: {e}")
        if channel == FEISHU_CHANNEL or channel == LARK_CHANNEL:
            print("❌❌❌ SaaS飞书构建中ODR拉取失败！请联系CI Oncall进行查看！")
        else:
            print("❌❌❌ KA构建ODR拉取失败，错误码将上传至交付平台！")
            job_id = os.getenv("WORKFLOW_JOB_ID")
            token_url = "https://delivery.bytedance.net/open/api/appauth/accesstoken"
            post_url = "https://delivery.bytedance.net/open-apis/build_task/report"
            auth_temp = get_auth_token(token_url)
            auth = basic_auth("1DVmpp", auth_temp)
            post_error_msg(post_url, job_id, auth, "305", "ODR资源下载失败，请发起Oncall检测ODR配置是否存在问题。")
        sys.exit(1)
