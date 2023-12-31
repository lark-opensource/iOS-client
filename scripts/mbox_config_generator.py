# -*- coding: utf-8 -*-
import glob
import json
import os

# 重新生成.mboxconfig文件

current_path = os.path.abspath(__file__)
parent_dir = os.path.dirname(os.path.dirname(current_path))
current_cwd = os.getcwd()
os.chdir(parent_dir)

podspec = []

for path in sorted(glob.glob("**/*.podspec", recursive=True), key=os.path.basename):
    if "Pods/" in path or "Example/" in path or "Mock/" in path:
        continue
    podspec.append(path)

config = {
    "podfile": "./Podfile",
    "podlock": "./Podfile.lock",
    "xcodeproj": "./Lark.xcodeproj",
    "podspecs": podspec,
    "plugins": {"MBoxLarkModManager": {"required_minimum_version": "1.0.1"}},
}
config_json = json.dumps(config, sort_keys=True, separators=(",", " : "), indent=2)
with open(os.path.join(parent_dir, ".mboxconfig"), "w") as f:
    f.write(config_json)

os.chdir(current_cwd)

print("可以使用Swift命令 (swift ./scripts/Tool/Sources/Tool/main.swift), 更新更快")