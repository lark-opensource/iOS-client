import os
import subprocess
import re
from commonFuntion import *
import argparse
import glob
import yaml
import plistlib
import json

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
    "TTMicroApp/TTMicroApp/Resources/Others/error-page.html",
    "TTMicroApp/TTMicroApp/Resources/Others/tmg_vconsole.html",
    "SuiteLogin/resources/help_ja_JP.html",
    "SuiteLogin/resources/help_zh_CN.html",
    "SuiteLogin/resources/help_en_US.html",
    "LarkUIKit/LarkUIKit/Resources/YTPlayerView-iframe-player.html",
    "DocsSDK/Resources/load_fail.html",
    "DocsSDK/Resources/DrivePreviewResources/MarkdownTemplate.html",
    "DocsSDK/Resources/DrivePreviewResources/CodeTemplate.html",
    "DocsSDK/Resources/calendar/calendarIndex.html",
    "DocsSDK/Resources/calendar_v2/mobile_index.html",
    "SKResource/Resources/comment_for_gadget.js",
    "MailSDK/Resources/mail-native-template/template/template.html",
    "MailSDK/Resources/mail-native-template/template/key.html",
    "MailSDK/Resources/SupportFiles/editor/mail_editor_index.html",
    "TencentQQSDK/TencentQQSDK/Assets/TencentOpenApi_IOS_Bundle.bundle/local.html",
    "MarkdownView/webassets/dist/index.html",
    "Lynx/Darwin/iOS/JSAssets/release/lynx_core.js",
    "Lynx/Darwin/iOS/JSAssets/release/lepus_bridge.js",
    "SKResource/Resources/DrivePreviewResources/excel.js",
    "LynxDevtool/Darwin/iOS/JSAssets/debug/lynx_core_dev.js",
    "LynxDevtool/Darwin/iOS/JSAssets/debug/redbox/umi.d95b0f2a.js",
    "LynxDevtool/Darwin/iOS/JSAssets/debug/redbox/umi.83af1562.js",
    "LarkSearchCore/resources/card-service-precise/template.js",
    "LarkSearchCore/resources/card-store/template.js",
    "ByteViewHybrid/resources/lynx/vote/create/template.js",
    "ByteViewHybrid/resources/lynx/vote/detail/template.js",
    "ByteViewHybrid/resources/lynx/vote/index/template.js",
    "ByteViewHybrid/resources/lynx/vote/panel/template.js",
    "ByteViewHybrid/resources/lynx/vote/participants/template.js",
    "ByteViewHybrid/resources/lynx/vote/picker/template.js",
    "LarkAI/resources/web_translate_plugin.js",
    "LarkSearchCore/resources/card-IG-cyclopedia/template.js",
    "LarkSearchCore/resources/card-universal-data/template.js",
    "LarkSearchCore/resources/card-cyclopedia-in-search/template.js",
    "TTMicroApp/Timor/Resources/Others/bd_core.js",
    "TTMicroApp/Timor/Resources/Others/blockit_core.js",
    "TTMicroApp/Timor/Resources/Others/errorpage.html",
    "OPBlock/resources/blockit_core.js"
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
            result_list = re.findall(r"\'(.*?)\'", line_str)
            if len(result_list) == 0:
                continue
            pod = result_list[0]
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


def __find_invalid_web_file(proj_dir, original_web_file_list,pod_name,subpath):
    glob_path = os.path.join(proj_dir,subpath) 
    print(glob_path)
    for file in glob.glob('{}/**/*.html'.format(glob_path), recursive=True):
        size = os.path.getsize(file)
        print("file:{},size:{}".format(file, size))
        if size < 50 * 1000:
            continue
        html_path = pod_name +  file.split(proj_dir)[1]
        if html_path not in original_web_file_list:
            print("非法文件：{}".format(file))
            return html_path

    for file in glob.glob('{}/**/*.js'.format(glob_path), recursive=True):
        size = os.path.getsize(file)
        print("file:{},size:{}".format(file, size))
        if size < 50 * 1000:
            continue
        js_path = pod_name + file.split(proj_dir)[1]
        if js_path not in original_web_file_list:
            print("非法文件：{}".format(file))
            return js_path


def __check_pdf_file(proj_dir, pdf_file_list,pod_name,subpath):
    invalid_list = []
    glob_path = os.path.join(proj_dir,subpath) 
    print(glob_path)
    for file in glob.glob('{}/**/*.pdf'.format(glob_path), recursive=True):
        pdf_file =  pod_name + file.split(proj_dir)[1]
        if pdf_file not in pdf_file_list:
            invalid_list
    if len(invalid_list) > 0:
        msg = '不允许提交PDF图片，请转为png图片再集成到工程\n.{}'.format(invalid_list)
        raise Exception(msg)
    else:
        print("pdf合法")


def __check_web_file(proj_dir, web_file_list,pod_name,subpath):
    invalid_web_file = __find_invalid_web_file(proj_dir, web_file_list,pod_name,subpath)
    if invalid_web_file:
        msg = '''文件：[{}]不合法,超过50K的js、html文件需要压缩为zip才能合到master分支'''.format(invalid_web_file)
        raise Exception(msg)
    else:
        print("web文件网页合法")


png_threshold = 20 * 1000 #阈值20K
# png_threshold = 30 #阈值30K

def checkPng(proj_dir):
    print(os.path.abspath(proj_dir))
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
        msg = '''图片：{}\n\n以上超过限额20K，需要压缩或者转为网图，如误报请联系@宋龙彪'''.format(msg)
        print(msg)
        sendBotMsg("https://open.feishu.cn/open-apis/bot/hook/4290db362d404f06b8fb81eb122b083c", "ios-client或者messenger有超过20K的图片", "{}".format(msg))
        raise Exception(msg)
    else:
        print("png合法")


def __get_pod_source_match(podspec_path,pod_name):
    matchArr = []
    podspec_file = os.path.join(podspec_path,pod_name + '.podspec')
    podspec_json_file = os.path.join(podspec_path,pod_name + '.podspec.json')
    os.system("bundle exec pod ipc spec {} > {}".format(podspec_file,podspec_json_file))
    podspec_json = {}
    if not os.path.exists(podspec_json_file):
        return matchArr
    with open(podspec_json_file,'r') as load_f:
        podspec_json_str = load_f.read()
        preArr = podspec_json_str.split("{")
        preArr[0] = ""
        podspec_json_str = "{".join(preArr)
        lastArr = podspec_json_str.split("}")
        lastArr[len(lastArr)-1] = ''
        podspec_json_str = "}".join(lastArr)
        podspec_json = json.loads(podspec_json_str)
    matchArr += podspec_json.get('resources',[])
    if 'resource' in podspec_json:
        matchArr.append(podspec_json.get('resource'))
    for value  in podspec_json.get('resource_bundles',{}).values():
        if isinstance(value,str):
            matchArr.append(value)
        elif isinstance(value,list):
            matchArr += value
    for subspec in podspec_json.get('subspecs',[]):
        matchArr += subspec.get('resources',[])
        if  'resource' in subspec:
            matchArr.append(subspec.get('resource'))
        for value  in subspec.get('resource_bundles',{}).values():
            if isinstance(value,str):
                matchArr.append(value)
            elif isinstance(value,list):
                matchArr += value
    return matchArr

def __main():
    p = argparse.ArgumentParser()
    p.add_argument('--dir')

    if "MR_APPSIZE_CHECK_ENABLE" in os.environ:
        if os.environ.get("MR_APPSIZE_CHECK_ENABLE","") == "false":
            print("关闭包大小资源检测")
            return

    args = p.parse_args()
    proj_dir = args.dir

    #扫描pods文件夹
    pods_dir = os.path.join(proj_dir,"Pods/")
    checkPng(pods_dir)
    __check_web_file(pods_dir, g_web_file_list,"","")
    __check_pdf_file(pods_dir, pdf_list,"","")
    #monorepo 改造适配
    monorepo_pods = []
    if 'TARGETCODEPATH' in os.environ.keys():
        with open("{}/main_repo_pods.json".format(os.environ.get("TARGETCODEPATH"),'r')) as jsonfile:
            monorepo_pods = json.load(jsonfile)
        print("monorepo修改模块:{}".format(monorepo_pods))
        bits_component_path = os.path.join(proj_dir, ".bits/bits_components.yaml")
        component_podfile_path = ""
        with open(bits_component_path, encoding='UTF-8') as yaml_file:
            components_config = yaml.load(yaml_file, Loader=yaml.FullLoader)['components_publish_config']
        for podname in monorepo_pods:
            if podname not in components_config.keys():
                print("仓库：bits_components.yaml不存在{}配置".format(podname))
                continue
            relative_path = components_config[podname]['archive_source_path']
            if relative_path.startswith('/'):
                component_podfile_path = proj_dir + relative_path
            else:
                component_podfile_path = os.path.join(proj_dir, relative_path)
            matchs = __get_pod_source_match(component_podfile_path,podname)
            print(matchs)
            for match in matchs:
                subPath = match.split('/')
                subPath.pop()
                subPathStr = '/'.join(subPath)
                png_glob_path = os.path.join(component_podfile_path,subPathStr) 
                checkPng(png_glob_path)
                __check_web_file(component_podfile_path, g_web_file_list,podname,subPathStr)
                __check_pdf_file(component_podfile_path, pdf_list,podname,subPathStr)
    #处理单仓所组件问题
    if "CUSTOM_CI_MR_DEPENDENCIES_COPY" in os.environ:
        print("子仓check")
        mr_info_str = "{}"
        if len(os.environ.get("CUSTOM_CI_MR_DEPENDENCIES_COPY","")) > 0:
            mr_info_str = os.environ.get("CUSTOM_CI_MR_DEPENDENCIES_COPY")
        mr_info =  json.loads(mr_info_str)
        print(mr_info)
        for key,value in mr_info.items():
            if 'git' not in value.keys():
                continue
            # 获取仓库名字
            project_name = value['git'].split('/')[-1].replace('.git','')
            # bit的工作目录
            offline_workspace = os.environ.get('BIT_WORKSPACE_DIR')
            #子仓的下载
            temp_dir = os.path.join(offline_workspace, 'temp')
            #
            dependency_project_dir = os.path.join(temp_dir, project_name)

            bits_component_path = os.path.join(dependency_project_dir, ".bits/bits_components.yaml")

            podpath = key

            if not os.path.exists(bits_component_path):
                print("仓库：{}下bits_components.yaml不存在".format(key))
                # 不是单仓多组件 直接扫描
                matchs = __get_pod_source_match(dependency_project_dir,key)

                for match in matchs:
                    subPath = match.split('/')
                    subPath.pop()
                    subPathStr = '/'.join(subPath)
                    png_glob_path = os.path.join(dependency_project_dir,subPathStr) 
                    checkPng(png_glob_path)
                    __check_web_file(dependency_project_dir, g_web_file_list,podpath,subPathStr)
                    __check_pdf_file(dependency_project_dir, pdf_list,podpath,subPathStr)


            else:
                component_podfile_path = ""
                with open(bits_component_path, encoding='UTF-8') as yaml_file:
                    components_config = yaml.load(yaml_file, Loader=yaml.FullLoader)['components_publish_config']
                    if key not in components_config.keys():
                        print("仓库：bits_components.yaml不存在{}配置".format(key))
                        continue
                    relative_path = components_config[key]['archive_source_path']
                    if relative_path.startswith('/'):
                        component_podfile_path = dependency_project_dir + relative_path
                    else:
                        component_podfile_path = os.path.join(dependency_project_dir, relative_path)
                print("仓库：{}开始扫描".format(component_podfile_path))
                matchs = __get_pod_source_match(component_podfile_path,key)

                for match in matchs:
                    subPath = match.split('/')
                    subPath.pop()
                    subPathStr = '/'.join(subPath)
                    png_glob_path = os.path.join(component_podfile_path,subPathStr) 
                    checkPng(png_glob_path)
                    __check_web_file(component_podfile_path, g_web_file_list,podpath,subPathStr)
                    __check_pdf_file(component_podfile_path, pdf_list,podpath,subPathStr)
 


    plist_path = os.path.join(proj_dir, "Lark/Info.plist")
    if not os.path.exists(plist_path):
        # 目前会跑LarkMessenger工程，Messenger的info文件放在LarkMessengerDemo/Info.plist
        plist_path = os.path.join(proj_dir, "LarkMessengerDemo/Info.plist")


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
