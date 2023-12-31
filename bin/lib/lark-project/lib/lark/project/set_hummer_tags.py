#!/usr/bin/env python3
"""
import from https://bytedance.feishu.cn/wiki/wikcnAbDdAubY9sCyyxHyQa0iyd#zFLiDF
"""

# usage:
# export WORKSPACE_PATH=/Users/kila/Desktop/Workspace/tt_app_ios/Article/Article.xcworkspace
# cat << EOF | xcrun python3 - <key> <value> <key> <value> <key> <value>

import os
import sys
import hashlib
import ssl
import base64
import traceback
from urllib.request import urlretrieve
from urllib import request

try:

    def get_file_md5(file_path):
        if not os.path.exists(file_path):
            return "notexists"

        def file_as_bytes(file):
            with file:
                return file.read()

        return hashlib.md5(file_as_bytes(open(file_path, "rb"))).hexdigest()

    def check_update_tos_file(url, save_path, ssl_verified=False):
        context = ssl._create_unverified_context()
        if ssl_verified:
            context = ssl.create_default_context()
        req = request.Request(url, method="HEAD")
        res = request.urlopen(req, context=context, timeout=3)
        base64bytes = res.headers["content-md5"].encode("ascii")
        tos_md5 = base64.b64decode(base64bytes).hex()
        if os.path.exists(save_path):
            file_md5 = get_file_md5(save_path)
            if file_md5 == tos_md5:
                return False
        return True

    tools_url = "https://ios.bytedance.net/wlapi/tosDownload/iosbinary/indexstore/build_infer_log_tools.py"
    workdir = os.path.expanduser("~/Library/Caches/com.bytedance.buildinfra/common/bin")
    os.makedirs(workdir, exist_ok=True)
    tools_save_path = os.path.join(workdir, "build_infer_log_tools.py")
    if not os.path.exists(tools_save_path):
        urlretrieve(tools_url, tools_save_path)
    else:
        should_update = False
        try:
            should_update = check_update_tos_file(tools_url, tools_save_path)
        except Exception:
            pass
        if should_update:
            urlretrieve(tools_url, tools_save_path)
    sys.path.append(workdir)
    from build_infer_log_tools import set_optimize_keys, get_optimize_keys

    set_optimize_keys()
    print(get_optimize_keys())
except Exception as err:
    exit_reason = str(err)
    os.system(
        '{ /usr/bin/curl -m 30 -X GET -G -s --data-urlencode "text=%s\n%s" --data-urlencode "username=lijunliang.9819" https://ios.bytedance.net/wlapi/sendMessage > /dev/null || echo [Error]hummer report error; } &'
        % (exit_reason, traceback.format_exc())
    )
    print("出现异常。设置环境变量失败", file=sys.stderr)
