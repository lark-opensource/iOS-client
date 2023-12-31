# -*- coding:utf-8 -*-
import argparse
import os
import datetime
import shutil
import glob
import re
import sys
import hashlib
import yaml
import requests
import json
from distutils.version import StrictVersion
import stat

def get_PK150_team_mame():
    # 'https://pk150.bytedance.net/api/m150/dashboard/bizlines?product=Lark&platform=iOS&include_sys=false&include_unknown=false'
    headers = {
        'Content-Type': 'application/json'
    }
    res = requests.get(
        url='https://pk150.bytedance.net/api/m150/dashboard/bizlines?product=Lark&platform=iOS&include_sys=false&include_unknown=false',
        headers=headers)
    bizlines = res.json()["result"]['bizlines']
    biz_name_dic = {}
    for bizline in bizlines:
        biz_name_dic[bizline['id']] = bizline['name']
    return biz_name_dic

def get_res_rules():
    headers = {
        'Content-Type': 'application/json'
    }
    #https://pk150.bytedance.net/api/m150/dashboard/bizlines?product=Lark&platform=iOS&include_sys=false&include_unknown=false 获取团队名字用
    res = requests.get(
        url = "https://pk150.bytedance.net/api/m150/dashboard/bizline_config?product=Lark&platform=iOS",
        headers = headers)
    res_bin_rules = res.json()['result']['config']['bin']['rules']
    res_bin_rules_dic = {}
    res_bin_rules_name_dic = {}
    #获取team显示名字
    biz_name_dic = get_PK150_team_mame()

    #获取模块匹配业务
    for rule in res_bin_rules:
        res_bin_rules_dic[rule['value']] = rule['bizline']
        if rule['bizline'] not in biz_name_dic:
            print(rule['bizline'])
            print(rule['value'])
            continue
        res_bin_rules_name_dic[rule['value']] = biz_name_dic[rule['bizline']]
    return res_bin_rules_name_dic

def json_to_yaml(data,path):
    stra = json.dumps(data)
    dyaml = yaml.load(stra,Loader=yaml.FullLoader)
    stream = open(path, 'w+')
    yaml.safe_dump(dyaml,stream,default_flow_style=False)

def update_search_file(project_dir):
    bizs = get_res_rules()
    yaml_json = {
        "reporter": "json",
        "included":[
            "./Pods/LarkChat"
        ],
        "blacklist_symbols":[
            "AppDelegate",
            "viewDidLoad"
        ],
        "symbol_regex": "^((?!.*(Gender)).)*$",
        "blacklist_superclass":[
            "UITableViewCell",
            "LanguageManager"
        ],
        "output_file":"pecker.result.json"
    }
    for key,value in bizs.items():
        if key in ['SQLite.swift','SQLiteMigrationManager.swift']:
            continue
        yaml_json["included"].append("./Pods/{}".format(key))
    json_to_yaml(yaml_json,"{}/.pecker.yml".format(project_dir))

#下载合适pecker
def checkPecker():
    p=os.popen("xcodebuild -version")
    XcodeVersion = p.read().split('\n')[0].split(" ")[1]
    headers = {
        'Content-Type': 'application/json'
    }
    res = requests.get(
        url='http://tosv.byted.org/obj/lark-ios/pecker_setting.json',
        headers=headers)
    pecker_setting = res.json()
    pecker_version = 0
    for version in pecker_setting['versions']:
       if StrictVersion(XcodeVersion) >= StrictVersion(version):
            pecker_version = version
            break
    print(pecker_version)
    if pecker_version == 0:
        return
    pecker_url = pecker_setting['versinoInfo'][pecker_version]
    peckerPath =  os.path.abspath(__file__).replace('run_pecker.py',"") + 'pecker'
    if os.path.exists(peckerPath):
        os.remove(peckerPath)
    down_res = requests.get(pecker_url)
    with open(peckerPath,'wb') as file:
        file.write(down_res.content)
    os.chmod(peckerPath, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)


if __name__ == '__main__':
    checkPecker()
    project_dir = os.path.abspath(__file__).replace("/bin/Pecker/run_pecker.py","")
    update_search_file(project_dir)
    p = os.popen('xcodebuild -showBuildSettings -workspace {}/Lark.xcworkspace -scheme Lark'.format(project_dir))
    xcode_build_setting_json = p.read()
    lines = xcode_build_setting_json.split("\n")

    for line in lines:
        if " SYMROOT = " in line:
            symroot_path = line.split("SYMROOT = ")[1]
            parent_path = os.path.dirname(os.path.dirname(symroot_path))
            dataStore_path = os.path.join(parent_path, "Index/DataStore")
            if not os.path.exists(dataStore_path):
                print("工程index文件不存在")
                work_space_file = os.path.join(project_dir, "Lark.xcworkspace")
                os.system("open {}".format(work_space_file))
            command = "{}/bin/Pecker/pecker --path {} -i {}  --language swift ".format(project_dir,project_dir, dataStore_path)
            print(command)
            os.system(command)
            break