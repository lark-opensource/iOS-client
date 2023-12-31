#!/usr/local/bin/python3
# coding: utf-8

import requests
import json
import os
import subprocess
import sys
import re
import git

# 获取精简包版本
def get_value_from_current_revision(key):
    with open('Modules/SpaceKit/Libs/SKResource/Resources/eesz-zip/current_revision', 'r') as f:
        lines = f.readlines()
        lineCount = len(lines)
        for lineIndex in range(lineCount):
            line = lines[lineIndex]
            match = re.search(f'^{key}:', line)
            if match:
                components = line.split(":")
                if len(components) >= 2:
                    return components[1].replace('\n', '')
    return ''

def check_full_pkg_release_impl(slim_pkg_version, app_version):
    # 国内线上 https://cloud.bytedance.net/gecko/site/app/1944/deployment/1414/channel/107940516
    success = request_gecko(slim_pkg_version, app_version, "170fde123c7a011616dd5e6856ec443b", "https://gecko-bd.feishu.cn")
    if not success:
        print(f'❌{slim_pkg_version}对应的完整包未在Gecko国内线上环境发布，请联系前端值班同学确认')
        sys.exit(-1)
    # 国内内测 https://cloud.bytedance.net/gecko/site/app/1944/deployment/1413/channel/107565617
    success = request_gecko(slim_pkg_version, app_version, "2f8feb7db4d71d6ddf02e76668896c41", "https://gecko-bd.feishu.cn")
    if not success:
        print(f'❌{slim_pkg_version}对应的完整包未在Gecko国内内测环境发布，请联系前端值班同学确认')
        sys.exit(-1)
    # 海外线上 https://cloud-i18n.bytedance.net/gecko/site/app/20/deployment/37/channel/22523069
    success = request_gecko(slim_pkg_version, app_version, "170fde123c7a011616dd5e6856ec443b", "https://gecko-va.byteoversea.com")
    if not success:
        print(f'❌{slim_pkg_version}对应的完整包未在Gecko海外线上环境发布，请联系前端值班同学确认')
        sys.exit(-1)
    # 海外内测 https://cloud-i18n.bytedance.net/gecko/site/app/20/deployment/36/channel/22523407
    success = request_gecko(slim_pkg_version, app_version, "2f8feb7db4d71d6ddf02e76668896c41", "https://gecko-va.byteoversea.com")
    if not success:
        print(f'❌{slim_pkg_version}对应的完整包未在Gecko海外内测环境发布，请联系前端值班同学确认')
        sys.exit(-1)
    # BOE https://cloud-boe.bytedance.net/gecko/site/app/704/deployment/11509/channel/12448
    success = request_gecko(slim_pkg_version, app_version, "ded3766bfe7bbc722fb5eb534ad4b11e", "http://gecko.snssdk.com.boe-gateway.byted.org")
    if not success:
        print(f'❌{slim_pkg_version}对应的完整包未在Gecko BOE环境发布，请联系前端值班同学确认')
        sys.exit(-1)

def request_gecko(version, app_version, access_key, url):
    url += "/src/server/v3/package"
    json = {
        'local': {},
        'custom': {
            access_key: {
                "slim_res_version": version,
                "business_version": app_version
            }
        },
        "req_meta": {
            "req_type": 1
        },
        "common": {
            "region": "CN",
            "os": 1,
            "app_version": app_version,
            "ac": "WiFi",
            "device_id": "7119370002196973100",
            "os_version": "15.4.1",
            "device_platform": "iphone",
            "aid": 1161,
            "device_model": "iPhone13,2",
            "sdk_version": "2.0.1-rc.1",
            "app_name": "Lark"
        },
        "deployments": {
            access_key: {
                "group_name": "default",
                "target_channels": [{
                    "c": "docs_fullpkg_channel"
                }]
            }
        }
    }
    response = requests.post(url, json = json).json()
    status = response.get("status")
    if status != 0:
        return False
    message = response.get("message")
    if message != "success":
        return False
    data = response.get("data")
    if data is None:
        return False
    packages = data.get("packages")
    if packages is None:
        return False
    full_pkgs = packages.get(access_key)
    if full_pkgs is None:
        return False
    return len(full_pkgs) > 0

# 检测完整包是否已在gecko发布
def check_full_pkg_release():
    # 只在改动了资源包才检测
    if check_pkg_version_changed():
        current_branch_slim_pkg_version = get_value_from_current_revision('version')
        # app_version不影响完整包查询，这里先写死
        check_full_pkg_release_impl(current_branch_slim_pkg_version, '5.18.0')
    else:
        print(f'has not modify eesz-zip')

# 检测两个分支间 Lynx 版本是否变化
def check_pkg_version_changed():
    target_branch = os.environ.get("WORKFLOW_REPO_TARGET_BRANCH")
    current_branch = os.environ.get("WORKFLOW_REPO_BRANCH")
    changed_file_list = subprocess.check_output(['git', 'diff', '--name-only', 'origin/' + current_branch + '..origin/' + target_branch]).split(b'\n')
    for changed_file in changed_file_list:
        if changed_file == b'Modules/SpaceKit/Libs/SKResource/Resources/eesz-zip/current_revision':
            return True
    return False

if __name__ == '__main__':
    check_full_pkg_release()
