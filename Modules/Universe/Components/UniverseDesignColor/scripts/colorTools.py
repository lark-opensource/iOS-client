import openpyxl
import datetime
import os
import re
import subprocess
import sys
import shutil
import webbrowser

# 打开Excel文件
def get_excel_file_name() -> str:
    try:
        # 获取当前目录
        current_dir = os.getcwd()
        # 查找xlsx文件
        xlsx_files = [f for f in os.listdir(current_dir) if f.endswith(".xlsx")]
        # 检查文件数量
        if len(xlsx_files) == 1:
            # 如果只有一个文件，返回文件名
            filename = xlsx_files[0]
            # 返回文件名
            return filename
        elif len(xlsx_files) == 0:
            url = 'https://bytedance.feishu.cn/sheets/shtcnVflDod3WTZcDYCPa7tEoLc?sheet=7laq1O&table=tblQeITUEO1QUWGj&view=vewygPTir6'
            webbrowser.open(url, new=2, autoraise=True)
            url = 'https://bytedance.feishu.cn/docx/UUnsdN5rTouYMkxZA4CcIdtWnre'
            webbrowser.open(url, new=2, autoraise=True)
            raise ValueError("当前目录不存在 xlsx 文件，请确保已移动进当前文件夹，文件下载可参考 README")
        else:
            # 否则，抛出异常
            raise ValueError("当前目录存在多个 xlsx 文件，请移除多余文件")
    except Exception as e:
        delete_cache()
        # 处理异常
        sys.exit(1)


def replace_file(file_name, swift_code):
    # 获取脚本文件的父目录
    parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    # 查找父目录下的名为file_name的文件
    for root, dirs, files in os.walk(parent_dir):
        if file_name in files:
            file_path = os.path.join(root, file_name)
            # 直接替换文件内容
            with open(file_path, 'w') as file:
                file.write(swift_code)
            print('成功替换文件：', file_path)
            return
    print('文件不存在：', file_name)
    raise ValueError(f"文件不存在: {file_name}")


def process_value(color_value: str) -> str:
    try:
        # 如果包含 linear-gradient，则忽略此行
        if "linear-gradient" in color_value:
            return color_value.replace("-", "").replace("/", "")

        # 如果包含 / 或 -，将其后的第一个字母大写，如果后跟的是数字，也保留
        if "/" in color_value or "-" in color_value:
            for sep in ("/", "-"):
                if sep in color_value:
                    parts = color_value.split(sep)
                    new_parts = []
                    for i, part in enumerate(parts):
                        if i > 0 and len(part) > 0:
                            if part[0].isdigit():
                                new_parts.append(part[0] + part[1:].capitalize())
                            else:
                                new_parts.append(part[0].upper() + part[1:])
                        else:
                            new_parts.append(part)
                    color_value = sep.join(new_parts)

        # 如果包含%，优先转换为.withAlphaComponent()
        if "%" in color_value:
            match = re.match(r"^[0-9]*\.?[0-9]+%$", color_value.split(",")[-1])
            if not match:
                raise ValueError(f"Invalid color value: {color_value}.")
            alpha = float(color_value.split(",")[-1][:-1])/100.0
            color_value = color_value.split(",")[0]
            if "#" in color_value:
                color_value = f"rgb(0x{color_value[1:]})" + f".withAlphaComponent({alpha})"
            else:
                color_value = f"{color_value}.withAlphaComponent({alpha})"

        # 如果包含#。转化为rgb(0x)
        if "#" in color_value:
            color_value = "rgb(0x" + color_value[1:] + ")"

        return color_value.replace("-", "").replace("/", "")
    except Exception as e:
        print(str(e))
        # 处理异常
        return ""
    

def delete_cache():
    # 删除所有的.xlsx文件
    [os.remove(f) for f in os.listdir(".") if f.endswith(".xlsx")]
    # 删除__pycache__目录
    shutil.rmtree("__pycache__")


workbook = openpyxl.load_workbook(get_excel_file_name())
try:
    # 获取工作表
    keys_sheet = workbook.worksheets[0]
    tokens_Sheet = workbook.worksheets[1]
    biz_token_sheet = workbook.worksheets[3]

    # 检查工作表数量是否足够
    if len(workbook.worksheets) < 3:
        raise ValueError("工作表数量不足，请联系相关 UX 确认是否 Token 文档有大调整，此脚本可能已过时")
except Exception as e:
    delete_cache()
    sys.exit(1)

# 获取当前日期和时间，并格式化输出
formatted_time = datetime.datetime.now().strftime("%Y年%m月%d日 %H:%M:%S")
# 获取用户名, 如果没有获取到用户名，则使用系统用户名代替
git_username = subprocess.check_output(['git', 'config', 'user.name']).decode().strip()
if not git_username:
    git_username = os.getlogin()

# 颜色名称映射关系
color_map = {
    'N': 'Neutral',
    'R': 'Red',
    'O': 'Orange',
    'Y': 'Yellow',
    'S': 'Sunflower',
    'L': 'Lime',
    'G': 'Green',
    'T': 'Turquoise',
    'W': 'Wathet',
    'B': 'Blue',
    'I': 'Indigo',
    'P': 'Purple',
    'V': 'Violet',
    'C': 'Carmine',
}
