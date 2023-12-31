#!/usr/local/bin/python3
# coding: utf-8

import requests
import json
import os
import subprocess
import sys

# 获取前端资源包中的release_version字段，得到对应的分支信息
def get_web_resource_branch_version():
    current_eesz_release_version = subprocess.getoutput('cat Modules/SpaceKit/Libs/SKResource/Resources/eesz-zip/current_revision | grep release_version')
    if current_eesz_release_version is None:
        return ''
    components = current_eesz_release_version.split(":")
    if len(components) >= 2:
        return components[1]
    else:
        return ''

# 检测前端资源包分支和Native分支版本是否一样
def check_web_resource_branch():
    #获取Native的target_branch
    target_branch = os.environ.get("WORKFLOW_REPO_TARGET_BRANCH")
    if target_branch is None:
        target_branch = os.environ.get("CUSTOM_CI_HOST_TARGET_BRANCH")
    components = target_branch.split("/")
    #只在目标分支为release时才检测
    if len(components) >= 2 and components[0] == 'release':
        target_branch_version = components[1]
        web_branch_verison = get_web_resource_branch_version()
        if (len(web_branch_verison) > 0 and len(target_branch_version) > 0):
            if target_branch_version != web_branch_verison:
                print(f'current web offline resource release version ({web_branch_verison}) is not equal to native branch version({target_branch_version})')
                sys.exit(-1)
            else:
                print(f'current web offline resource release version ({web_branch_verison}) is equal to native branch version ({target_branch_version})')
        else:
            print(f'current web offline resource release version ({web_branch_verison}) is empty or native branch version({target_branch_version}) is empty')
    else:
        print(f'target branch is not release ({target_branch})')

def check_web_resource_changed():
    target_branch = os.environ.get("WORKFLOW_REPO_TARGET_BRANCH")
    current_branch = os.environ.get("WORKFLOW_REPO_BRANCH")
    changed_file_list = subprocess.check_output(['git', 'diff', '--name-only', 'origin/' + current_branch + '..origin/' + target_branch]).split(b'\n')
    for changed_file in changed_file_list:
        if changed_file == b'Modules/SpaceKit/Libs/SKResource/Resources/eesz-zip/current_revision':
            return True
    return False

if __name__ == '__main__':
    web_resource_changed = check_web_resource_changed()
    if web_resource_changed:
        print("web resource changed, checking web resource branch")
        check_web_resource_branch()
    else:
        print("web resource not changed, skipping web resoruce branch check")
