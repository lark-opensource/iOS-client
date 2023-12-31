# -*- coding: utf-8 -*- 
import requests
import json
import zipfile
from io import BytesIO
import os
import shutil
import warnings

# 忽略https的警告
warnings.filterwarnings('ignore')
# 目标文件夹
OFFLINE_FOLDER = "./offline"
# 配置文件名
CONFIG_NAME = "offline/config.json"

# 请求settings，获取bdp_offline_zip字段
def request_offline_settings():
    settings = json.loads(requests.get("http://ib.snssdk.com/service/settings/v3/?caller_name=iron_man").content.decode("utf-8"))
    return settings["data"]["settings"]["bdp_offline_zip"]

# 从指定url下载资源，并将资源解压到unzip_folder
def download_and_unzip_offline_zip(url, unzip_folder):
    res_zip = zipfile.ZipFile(BytesIO(requests.get(url, verify = False).content))
    res_zip.extractall(unzip_folder)

# 判断是否需要更新
def isNeedUpdate(origin_config, target_md5):
	try:
		if origin_config["md5"] != target_md5:
			return True
	except:
		pass	
	return False

# 更新内置离线包
def update_offline_zip(offline_settings):
	try:
	    # 读取本地config.json
	    origin_config = json.loads(open(CONFIG_NAME).read().decode("utf-8"))
	except:
	    origin_config = {}
	    
	is_need_update = False
	for key, value in offline_settings.items():
	    url = value["url"]
	    path = value["path"]
	    md5 = value["md5"]
	    if path in origin_config.keys() and not isNeedUpdate(origin_config[path], md5):
	        print("Packet \'" + path + '\' don\'t needs update')
	    else:
	        print("Packet \'" + path + '\' needs update')
	        # 下载需要更新的资源
	        download_and_unzip_offline_zip(url, OFFLINE_FOLDER)
	        is_need_update = True
	        
	if os.path.exists(OFFLINE_FOLDER):
	    # 更新config.json
	    open(os.path.join(CONFIG_NAME), 'w').write(json.dumps(offline_settings))
	    print("Update all packeta successfully")

if __name__ == "__main__":
    offline_settings = request_offline_settings()
    update_offline_zip(offline_settings)