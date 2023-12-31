import os
import glob
import json

# 本脚本用以生成bits平台推荐组件配置文件

current_path = os.path.abspath(__file__)
parent_dir = os.path.dirname(os.path.dirname(current_path))
current_cwd = os.getcwd()
os.chdir(parent_dir)

podspec = []

for path in sorted(glob.glob("**/*.podspec", recursive=True), key=os.path.basename):
    if "Pods/" in path or "Example/" in path or "Mock/" in path:
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

modules_path = os.path.join(parent_dir, 'modules.json')

if not os.path.exists(modules_path):
    os.system('touch modules.json')

with open(os.path.join(parent_dir, 'modules.json'), 'w') as f:
    config_json = json.dumps(podspec, sort_keys=True, separators=(",", " : "), indent=2)
    f.write(config_json)

os.chdir(current_cwd)

print("可以使用Swift命令 (swift ./scripts/Tool/Sources/Tool/main.swift), 更新更快")