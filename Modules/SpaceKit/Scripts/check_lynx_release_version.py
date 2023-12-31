#!/usr/local/bin/python3
# coding: utf-8

import requests
import json
import os
import subprocess
import sys

# 获取Lynx资源包中的branch字段，得到对应的分支信息或release版本号
# 开发分支是 master, release 分支为 v/X.XX.0, 只返回版本号
def get_lynx_resource_branch():
    current_lynx_branch = subprocess.getoutput('cat Modules/SpaceKit/Libs/SKResource/Resources/Lynx/current_revision | grep branch')
    if current_lynx_branch is None:
        return ''
    components = current_lynx_branch.split(":") # branch:v/6.0.0
    if len(components) >= 2:
        lynx_branch = components[1]
        sub_components = lynx_branch.split("/")
        if len(sub_components) == 2 and sub_components[0] == 'v':
            # release 分支返回版本号
            return sub_components[1]
        else:
            # master 或其他分支返回完整分支名
            return lynx_branch
    else:
        return ''

# 检测前端资源包分支和Native分支版本是否一样
def check_lynx_resource_branch():
    #获取Native的target_branch
    target_branch = os.environ.get("WORKFLOW_REPO_TARGET_BRANCH")
    components = target_branch.split("/")
    lynx_branch_verison = get_lynx_resource_branch()
    if len(components) >= 2 and components[0] == 'release':
        # release 分支需判断版本号是否一致
        target_branch_version = components[1]
        if (len(lynx_branch_verison) > 0 and len(target_branch_version) > 0):
            if target_branch_version != lynx_branch_verison:
                print(f'current lynx resource release version ({lynx_branch_verison}) is not equal to native branch version({target_branch_version})')
                print(f'只允许相同 release 分支的 lynx 包合入')
                sys.exit(-1)
            else:
                print(f'current lynx resource release version ({lynx_branch_verison}) is equal to native branch version ({target_branch_version})')
        else:
            print(f'current lynx resource release version ({lynx_branch_verison}) is empty or native branch version({target_branch_version}) is empty')
    elif len(components) == 1 and components[0] == 'develop':
        # 只允许 master 分支的 lynx 包合入 develop 分支
        if lynx_branch_verison != 'master':
            print(f'only lynx package from master can be merge into native develop branch, current is ({lynx_branch_verison})')
            print(f'只允许 master 分支的 lynx 包合入 develop 分支')
            sys.exit(-2)
        else:
            print(f'current lynx branch (master) match native develop branch (develop)')
    else:
        print(f'target branch is not release or master ({target_branch})')

# 检测两个分支间 Lynx 版本是否变化
def check_lynx_version_changed():
    target_branch = os.environ.get("WORKFLOW_REPO_TARGET_BRANCH")
    current_branch = os.environ.get("WORKFLOW_REPO_BRANCH")
    changed_file_list = subprocess.check_output(['git', 'diff', '--name-only', 'origin/' + current_branch + '..origin/' + target_branch]).split(b'\n')
    for changed_file in changed_file_list:
        if changed_file == b'Modules/SpaceKit/Libs/SKResource/Resources/Lynx/current_revision':
            return True
    return False

if __name__ == '__main__':
    lynx_changed = check_lynx_version_changed()
    if lynx_changed:
        print("lynx changed, checking lynx branch version")
        check_lynx_resource_branch()
    else:
        print("lynx not changed, skipping lynx version check")
