# -*- coding: utf-8 -*
import os
import time
import json
import argparse
import yaml

#python fixVersion.py  --workspace_dir "/Users/bytedance/Documents/Lark"  --mr_name "LarkChat" --mr_git "git@code.byted.org:lark/Lark-Messenger.git" --mr_commit_id "c047ca960586dc60bdba0500c75d43e0f21903ec"

p = argparse.ArgumentParser()
p.add_argument('--workspace_dir')
p.add_argument('--mr_name')
p.add_argument('--mr_git')
p.add_argument('--mr_commit_id')
args = p.parse_args()
options = vars(args)
print("\033[1;32m fixVersion.py脚本参数列表{}\033[0m".format(options))

HOST_PROJECT_DIR = args.workspace_dir
TEMP_DIR = os.path.join(HOST_PROJECT_DIR, 'temp')
PROJECT_NAME = args.mr_git.split('/')[-1].replace('.git','')
MR_NAME = args.mr_name
MR_GIT = args.mr_git
MR_COMMIT_ID = args.mr_commit_id

version_json_Dic = {}
json_path =  os.path.join(HOST_PROJECT_DIR, "version.json")
with open(json_path,'rb') as f:    
    version_json_Dic = json.load(f)
    f.close()

dependency_project_dir = os.path.join(TEMP_DIR, PROJECT_NAME)

    # 查找.bits/bits_components.yaml文件
bits_component_path = os.path.join(dependency_project_dir, ".bits/bits_components.yaml")
component_podfile_path = dependency_project_dir
if os.path.exists(bits_component_path):
    with open(bits_component_path, encoding='UTF-8') as yaml_file:
        components_config = yaml.load(yaml_file, Loader=yaml.FullLoader)['components_publish_config']
    
        relative_path = components_config[MR_NAME]['archive_source_path']
        if relative_path.startswith('/'):
            component_podfile_path = dependency_project_dir + relative_path
        else:
            component_podfile_path = os.path.join(dependency_project_dir, relative_path)

print(component_podfile_path)
current_address = component_podfile_path
for parent, dirnames, filenames in os.walk(current_address):
    for filename in filenames:
        if filename.split('.')[-1] not in ['swift','h','m','mm','cpp']:
            continue
        filepath = parent.split(component_podfile_path)[1]
        fileDic = {}
        fileDic['git'] = MR_GIT
        fileDic['checkoutInfo'] = MR_COMMIT_ID
        fileDic['repo_name'] = MR_NAME
        fileDic['version'] = "xxxx"#因为还没有生成版本号，所以这里占位用
        fileDic['path'] = os.path.join(filepath,filename)
        version_json_Dic[filename] = fileDic

with open(json_path,'w') as r:
    json.dump(version_json_Dic,r)
    r.close()

