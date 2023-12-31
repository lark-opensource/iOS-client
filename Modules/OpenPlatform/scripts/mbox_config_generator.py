# -*- coding: utf-8 -*-
import os
import glob
import json

# 重新生成.mboxconfig文件

current_path = os.path.abspath(__file__)
parent_dir = os.path.dirname(os.path.dirname(current_path))
current_cwd = os.getcwd()
os.chdir(parent_dir)

podspec = []

for path in glob.glob("**/*.podspec", recursive=True):
    if "Pods/" in path:
        continue
    podspec.append(path)

config = {
    "podfile": "Example/Podfile",
    "podlock": "Example/Podfile.lock",
    "xcodeproj": "Example/Lark.xcodeproj",
    "podspecs": podspec
}
config_json = json.dumps(config, indent=1)
with open(os.path.join(parent_dir, '.mboxconfig'), 'w') as f:
    f.write(config_json)

os.chdir(current_cwd)
