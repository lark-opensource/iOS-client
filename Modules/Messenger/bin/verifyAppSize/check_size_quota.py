import os
import subprocess
import re
from commonFuntion import *
import argparse
import glob
import yaml
import plistlib

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

g_web_file_list = [
    "EEMicroAppSDK/EEMicroAppSDK/Assets/littleapp_editor.js",
    "DocsSDK/Resources/DrivePreviewResources/purify.min.js",
    "DocsSDK/Resources/DrivePreviewResources/base64.min.js",
    "DocsSDK/Resources/DrivePreviewResources/marked.min.js",
    "DocsSDK/Resources/DrivePreviewResources/highlight.min.js",
    "DocsSDK/Resources/calendar/dist/index.js",
    "DocsSDK/Resources/calendar_v2/docs.vendor.js",
    "DocsSDK/Resources/calendar_v2/mobile_index-00d27193.js",
    "MailSDK/Resources/mail-native-template/template/src/swiper.min.js",
    "MailSDK/Resources/mail-native-template/template/src/index.js",
    "MailSDK/Resources/SupportFiles/commonJS/performance.js",
    "MarkdownView/webassets/dist/main.js",
    "EEMicroAppSDK/EEMicroAppSDK/Assets/littleapp_editor_index.html",
    "Timor/Timor/Resources/Others/error-page.html",
    "Timor/Timor/Resources/Others/tmg_vconsole.html",
    "SuiteLogin/resources/help_ja_JP.html",
    "SuiteLogin/resources/help_zh_CN.html",
    "SuiteLogin/resources/help_en_US.html",
    "LarkUIKit/LarkUIKit/Resources/YTPlayerView-iframe-player.html",
    "DocsSDK/Resources/load_fail.html",
    "DocsSDK/Resources/DrivePreviewResources/MarkdownTemplate.html",
    "DocsSDK/Resources/DrivePreviewResources/CodeTemplate.html",
    "DocsSDK/Resources/calendar/calendarIndex.html",
    "DocsSDK/Resources/calendar_v2/mobile_index.html",
    "MailSDK/Resources/mail-native-template/template/template.html",
    "MailSDK/Resources/mail-native-template/template/key.html",
    "MailSDK/Resources/SupportFiles/editor/mail_editor_index.html",
    "TencentQQSDK/TencentQQSDK/Assets/TencentOpenApi_IOS_Bundle.bundle/local.html",
    "MarkdownView/webassets/dist/index.html",
    "Lynx/iOS/Assets/release/lynx_core.js",
    "Pods/Lynx/iOS/Assets/debug/lynx_core.js",
    "Timor/Timor/Resources/Others/bd_core.js"
]

pdf_list = [
    "CalendarRichTextEditor/Resources/CalendarRichTextEditor.xcassets/Tool/icon_tool_disordelist_nor.imageset/icon_tool_disordelist_nor.pdf",
    "CalendarRichTextEditor/Resources/CalendarRichTextEditor.xcassets/Tool/icon_tool_divider_nor.imageset/icon_tool_divider_nor.pdf",
    "CalendarRichTextEditor/Resources/CalendarRichTextEditor.xcassets/Tool/icon_tool_bold_nor.imageset/icon_tool_bold_nor.pdf",
    "CalendarRichTextEditor/Resources/CalendarRichTextEditor.xcassets/Tool/icon_tool_italic_nor.imageset/icon_tool_italic_nor.pdf",
    "CalendarRichTextEditor/Resources/CalendarRichTextEditor.xcassets/Tool/icon_tool_ordelist_nor.imageset/icon_tool_ordelist_nor.pdf",
    "CalendarRichTextEditor/Resources/CalendarRichTextEditor.xcassets/Tool/icon_tool_horizontalline_nor.imageset/icon_tool_horizontalline_nor.pdf",
    "CalendarRichTextEditor/Resources/CalendarRichTextEditor.xcassets/Tool/icon_tool_underline_nor.imageset/icon_tool_underline_nor.pdf",
    "LarkCore/resources/Assets.xcassets/Doc/doc_ps_icon.imageset/doc_ps_icon.pdf"
]

def __change_bizs(pods):
    """
    根据pod返回相应的业务线列表
    :param pods:
    :return: 业务线列表
    """

    url = PK150_HOST + "/" + FIND_BIZ
    headers = {
        'Content-Type': 'application/json'
    }

    query = []
    for pod in pods:
        query.append({"type": "bin", "value": pod})

    params = {
        'product': "Lark",
        'platform': "iOS",
        'queries': query
    }
    res = requests.post(url=url, headers=headers, json=params)
    dict = res.json()
    ret = []
    if res.ok and dict['success']:
        bizlines = dict["result"]["bizlines"]
        for biz in bizlines:
            ret.append(biz['bizline_id'])
    return ret


def __findDiffPods(proj_dir):
    """
    根据pods来返回当前工程最后一次submit变化的业务线
    :param proj_dir: 工程地质
    :return: 业务线数组
    """

    output = subprocess.Popen("git diff HEAD\^ Podfile", shell=True, cwd=proj_dir, stdout=subprocess.PIPE)
    linesbytes = output.stdout.readlines()
    lines = ''
    pods = []
    for line in linesbytes:
        line_str = str(line, encoding="utf-8")
        lines += line_str

        group = re.search(r"^(\+( )+(pod ))", line_str)
        if group:
            line_str.split(",")
            pod = re.findall(r"\'(.*?)\'", line_str)[0]
            pods.append(pod)

        if re.search(r"^(\+( )+messenger_pod_version)", line_str):
            # 如果m，essenger_pod_version被修改了，说明messenger升级了，pod用LarkChat来发起请求就行
            pods.append("LarkChat")
    return pods

def __get_fail_bizs(version):
    headers = {
        'Content-Type': 'application/json'
    }
    param = {
        "version": version,
    }
    r = requests.post(CURRENT_VERSION_FAIL_BIZS, headers=headers, json=param)
    result = r.json()
    if result["code"] == 0:
        result["fail_bizs"]


def __check_valid(version, change_bizs):
    """
    检查是否通过quota验证
    :param version:
    :param change_bizs:
    :return: 是否通过验证
    """
    headers = {
        'Content-Type': 'application/json'
    }
    param = {
        "version": version,
        "change_bizs": change_bizs
    }
    r = requests.post(SUMBMIT_CHECK_VERIFY, headers=headers, json=param)
    if not r.ok:
        print("请求失败")
        return
    result = r.json()
    if result["code"] == 0:
        msg = result["msg"]
        print("验证通过,version: {},msg:{}".format(version, msg))
        return 0
    else:
        fail_bizs = result["fail_bizs"]
        msg = '''包体积验证不通过,当前版本: {}, 业务线：{}已经连续3个版本已超出限额，不允许提交, 配额机制可参考：" \
              "https://bytedance.feishu.cn/docs/doccnQQEodOImZmAj5kG4VV7CCe#'''.format(version, fail_bizs)
        raise Exception(msg)


def __find_invalid_web_file(proj_dir, original_web_file_list):
    for file in glob.glob('{}/Pods/**/*.html'.format(proj_dir), recursive=True):
        size = os.path.getsize(file)
        print("file:{},size:{}".format(file, size))
        if size < 50 * 1000:
            continue
        html_path = file.split("/Pods/")[1]
        if html_path not in original_web_file_list:
            print("非法文件：{}".format(file))
            return html_path

    for file in glob.glob('{}/Pods/**/*.js'.format(proj_dir), recursive=True):
        size = os.path.getsize(file)
        print("file:{},size:{}".format(file, size))
        if size < 50 * 1000:
            continue
        js_path = file.split("/Pods/")[1]
        if js_path not in original_web_file_list:
            print("非法文件：{}".format(file))
            return js_path


def __check_pdf_file(proj_dir, pdf_file_list):
    invalid_list = []
    for file in glob.glob('{}/Pods/**/*.pdf'.format(proj_dir), recursive=True):
        pdf_file = file.split("/Pods/")[1]
        if pdf_file not in pdf_file_list:
            invalid_list
    if len(invalid_list) > 0:
        msg = '不允许提交PDF图片，请转为png图片再集成到工程\n.{}'.format(invalid_list)
        raise Exception(msg)
    else:
        print("pdf合法")


def __check_web_file(proj_dir, web_file_list):
    invalid_web_file = __find_invalid_web_file(proj_dir, web_file_list)
    if invalid_web_file:
        msg = '''文件：[{}]不合法,超过50K的js、html文件需要压缩为zip才能合到master分支'''.format(invalid_web_file)
        raise Exception(msg)
    else:
        print("web文件网页合法")


png_threshold = 20 * 1000 #阈值20K
# png_threshold = 30 #阈值30K

def checkPng(proj_dir):
    pngMd5_path = os.path.join(BASE_DIR, "pngMd5.yml")
    with open(pngMd5_path, 'rb') as f:
        content = f.read()
        lark_md5_list = yaml.load(content, yaml.FullLoader)

    pngMd5_path = os.path.join(BASE_DIR, "messenger_pngMd5.yml")
    with open(pngMd5_path, 'rb') as f:
        content = f.read()
        messenger_md5_list = yaml.load(content, yaml.FullLoader)

    total_list = lark_md5_list + messenger_md5_list

    failList = []
    for file in glob.glob('{}/**/*.png'.format(proj_dir), recursive=True):
        md5 = get_file_md5(file)
        # print(md5)
        if md5 not in total_list:
            fsize = os.path.getsize(file)
            if fsize > png_threshold:
                failList.append((file, md5, fsize))
                # md5List.append(md5)

    print("添加reviewer成功")
    if len(failList) > 0:
        msg = ""
        for file in failList:
            msg += "图片:{},md5值:{},大小：{}K\n".format(file[0], file[1], file[2]/1000)
        msg = '''图片：{}\n\n以上超过限额20K，需要压缩或者转为网图，如误报请联系@黄健铭'''.format(msg)
        print(msg)
        sendBotMsg("https://open.feishu.cn/open-apis/bot/hook/4290db362d404f06b8fb81eb122b083c", "ios-client或者messenger有超过20K的图片", "{}".format(msg))
        raise Exception(msg)
    else:
        print("png合法")

def __main():
    p = argparse.ArgumentParser()
    p.add_argument('--dir')

    args = p.parse_args()
    proj_dir = args.dir

    checkPng(proj_dir)

    plist_path = os.path.join(proj_dir, "Lark/Info.plist")

    if not os.path.exists(plist_path):
        # 目前会跑LarkMessenger工程，Messenger的info文件放在LarkMessengerDemo/Info.plist
        plist_path = os.path.join(proj_dir, "LarkMessengerDemo/Info.plist")

    __check_web_file(proj_dir, g_web_file_list)
    __check_pdf_file(proj_dir, pdf_list)

    with open(plist_path, 'rb') as fp:
        plist = plistlib.load(fp)
        full_version = plist["CFBundleShortVersionString"]
        short_verdion = full_version.split("-", 1)[0]
        pods = __findDiffPods(proj_dir)
        __change_bizes = []
        if len(pods) == 0:
            print("本次修改没有涉及pod改动，直接退出")
            # 如果没有修改pods，可以直接退出检测
        else:
            print("本次修改的pod：{}".format(pods))
            __change_bizes = __change_bizs(pods)
            print("本次修改的业务线：{}".format(__change_bizes))
            __check_valid(short_verdion, __change_bizes)
        return
    raise Exception("plist文件打开失败")


if __name__ == '__main__':
    __main()
