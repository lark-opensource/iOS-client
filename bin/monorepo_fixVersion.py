# -*- coding: utf-8 -*
import os
import time
import json
import argparse
import yaml
import requests
import stat

#python fixVersion.py  --workspace_dir "/Users/bytedance/Documents/Lark"  --mr_name "LarkChat" --mr_git "git@code.byted.org:lark/Lark-Messenger.git" --mr_commit_id "c047ca960586dc60bdba0500c75d43e0f21903ec"

pre_time = time.time()
p = argparse.ArgumentParser()
p.add_argument('--Dir')

args = p.parse_args()
options = vars(args)
print("\033[1;32m fixVersion.py脚本参数列表{}\033[0m".format(options))

HOST_PROJECT_DIR = args.Dir
print(HOST_PROJECT_DIR)
version_json_Dic = {}
json_path =  os.path.join(HOST_PROJECT_DIR, "version.json")
if not os.path.exists(json_path):
    exit(0)
with open(json_path,'rb') as f:    
    version_json_Dic = json.load(f)
    f.close()

dependency_project_dir = HOST_PROJECT_DIR

    # 查找.bits/bits_components.yaml文件
bits_component_path = os.path.join(HOST_PROJECT_DIR, ".bits/bits_components.yaml")
component_podfile_path = dependency_project_dir
if os.path.exists(bits_component_path):
    with open(bits_component_path, encoding='UTF-8') as yaml_file:
        components_config = yaml.load(yaml_file, Loader=yaml.FullLoader)['components_publish_config']

        for module_name in components_config.keys():
            relative_path = components_config[module_name]['archive_source_path']
            if relative_path.startswith('/'):
                component_podfile_path = dependency_project_dir + relative_path
            else:
                component_podfile_path = os.path.join(dependency_project_dir, relative_path)

            current_address = component_podfile_path
            for parent, dirnames, filenames in os.walk(current_address):
                for filename in filenames:
                    if filename.split('.')[-1] not in ['swift','h','m','mm','cpp']:
                        continue
                    fileDic = version_json_Dic.get(filename,{})
                    fileDic['repo_name'] = module_name
with open(json_path,'w') as r:
    json.dump(version_json_Dic,r)
    r.close()

tos_url = "http://tosv.byted.org/obj/lark-ios/TOS"
tos_path =  os.path.abspath(__file__).replace('monorepo_fixVersion.py',"") + 'TOS'
if os.path.exists(tos_path):
    os.remove(tos_path)
down_res = requests.get(tos_url)
with open(tos_path,'wb') as file:
    file.write(down_res.content)
os.chmod(tos_path, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)
commit_id = os.popen("git rev-parse HEAD").read().replace('\n','')
if commit_id:
    print("上传version.json到Slarda")
    command = "{} map/iOS-client/{}.json {} name:map/iOS-client/{}.json".format(tos_path,commit_id,json_path,commit_id)
    print(command)
    os.system(command)

print(time.time() - pre_time)
