#!/usr/bin/python3
import os
import glob
import json

# 本脚本用以生成bits平台推荐组件配置文件

current_path = os.path.abspath(__file__)
parent_dir = os.path.dirname(os.path.dirname(current_path))
current_cwd = os.getcwd()
os.chdir(parent_dir)

podspec = []

for path in glob.glob("**/*.podspec", recursive=True):
    print(path)
    if "Pods/" in path:
        continue
    component_full_name = os.path.basename(path)
    component_name = component_full_name.split('.')[0]
    path = path.replace(component_full_name, "")
    dict = {
        "path": path,
        "components": [
            component_name
        ]
    }
    podspec.append(dict)

# 除了根据路径自动生成的自动组件推荐配置之外，还允许添加自定义的组件配置项
extraRecommendConfigs = [
    # Example文件发生变动之后，就推荐EcosystemShell占位组件
    {
        "path": "Example/",
        "components": ["EcosystemShell"]
    }
]

for recommendConfig in extraRecommendConfigs:
    podspec.append(recommendConfig)

modules_path = os.path.join(parent_dir, 'modules.json')

if not os.path.exists(modules_path):
    os.system('touch modules.json')

with open(os.path.join(parent_dir, 'modules.json'), 'w') as f:
    config_json = json.dumps(podspec, indent=1)
    f.write(config_json)

os.chdir(current_cwd)
