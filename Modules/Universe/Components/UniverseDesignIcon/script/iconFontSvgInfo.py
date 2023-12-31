# 导入依赖包
import xml.etree.ElementTree as etree
import os
import json

g = os.walk(r"./package/icons/")
normal_color = ['#2B2F36']
iconFonts = []
for path, dir_list, file_list in g:
    for file_name in file_list:
        file_path = os.path.join(path, file_name)
        # 打开文件
        tree = etree.ElementTree(file=file_path)  # 保证每次操作均为原始model文件
        root = tree.getroot()
        color_arr = []
        for child in root:
            if 'fill' not in child.attrib:
                continue
            if child.attrib['fill'] not in normal_color:
                color_arr.append(child.attrib['fill'])
        if len(color_arr) == 0:
            if "colorful" not in file_name:
                iconFonts.append(file_name)
print(iconFonts)
with open('./iconfontsvg.json', 'w') as f:
    json.dump(iconFonts, f)
