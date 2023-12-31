import sys
import time

try:
    from urllib2 import urlopen
except ImportError:
    from urllib.request import urlopen
import ssl
import argparse
import os
import subprocess
from tempfile import NamedTemporaryFile

ssl._create_default_https_context = ssl._create_unverified_context

DYNAMIC_SCRIPT_URL = "build-larkmobile.bytedance.net/tools/tos/settings_pyscript"

TAG = 'fetch dynamic script'

RETRY_FETCH = 5


def fetch_dynamic_script(tos_url, version, platform, bits_publish):
    # fetch dynamic script content
    url = 'https://%s?version=%s&platform=%s&bits_publish=%s' % (
        tos_url, version, platform, bits_publish)
    print('INFO: %s fetch_dynamic_script, start to fetch pyscript: url= %s' % (TAG, url))
    file_content = ''
    log_id = ''
    for i in range(RETRY_FETCH):
        time.sleep(i ^ 2)
        try:
            r = urlopen(url)
            log_id = r.headers['X-Tt-Logid']
            file_content = r.read().decode('unicode_escape')
            if len(file_content) > 0:
                print('INFO: %s fetch_dynamic_script, fetch pyscript success; X-Tt-Logid: %s' % (TAG, log_id))
                break
        except Exception as data:
            if hasattr(data, 'headers') and 'X-Tt-Logid' in data.headers:
                log_id = data.headers['X-Tt-Logid']
            print(data)
            print('WRAN: %s fetch_dynamic_script, get request failed; X-Tt-Logid: %s' % (TAG, log_id))

    if len(file_content) == 0:
        print('ERROR: %s fetch_dynamic_script, fetch pyscript failed' % TAG)
        sys.exit(1)

    with NamedTemporaryFile(delete=False, suffix='.py') as script_file:
        script_path = str(script_file.name)
        script_file.write(file_content[1: -1].encode('utf-8'))
        script_file.close()
        print('INFO: %s fetch_dynamic_script, script path: %s' % (TAG, script_path))

    return script_path


def parse_argv():
    parser = argparse.ArgumentParser(description='-e <env> -u <unit> -c <channel> -p <path>')
    parser.add_argument('-e', dest='env',
                        help='release|pre_release|staging, use | to split multiple values')
    parser.add_argument('-u', dest='unit',
                        help='eu_nc|eu_ea|boecn|boeva, use | to split multiple values, boecn and boeva only combine with staging')
    parser.add_argument('-b', dest='brand',
                        help='feishu|lark, use | to split multiple values')
    parser.add_argument('-c', dest='channel', help='the channel for KA')
    parser.add_argument('-p', dest='path', help='target file path', required=True)
    parser.add_argument('-o', dest='os', help='target platform, such as android / iphone / mac /pc',
                        required=True)
    parser.add_argument('-v', dest='version', help='the client version', required=True)
    parser.add_argument('-m', dest='deployMode', help='the service deployMode')
    parser.add_argument('-d', dest='debug', help='debug is enable')
    parser.add_argument('-s', dest='scene', help='supply "build" if need ka_info')
    parser.add_argument('-i', dest='bits_publish', help='bit publish build. if false, the cache config is allowed')
    parser.add_argument('-sp', dest='script_path', help='script_path. script file path')

    args = parser.parse_args()
    env = args.env if args.env is not None else "release"
    unit = args.unit if args.unit is not None else "eu_nc"
    brand = args.brand if args.brand is not None else "feishu"
    deploy_mode = args.deployMode if args.deployMode is not None else "saas"
    channel = args.channel
    output_path = args.path
    os = args.os
    version = args.version
    debug_enable = args.debug if args.debug is not None else False
    scene = args.scene if args.scene is not None else "build"
    bits_publish = "true" if args.bits_publish == "true" else "false"

    print(
        "INFO: %s parse_argv: env= %s unit= %s brand= %s os= %s version= %s channel= %s path= %s bits_publish= %s" % (
            TAG, env, unit, brand, os, version, channel, output_path, bits_publish))

    return env, unit, brand, os, version, deploy_mode, channel, output_path, debug_enable, scene, bits_publish


def system_run(cmd):
    p = subprocess.Popen(cmd, shell=True)  # ignore_security_alert
    return p.wait()


def quotes(str):
    return '"%s"' % str


def delete_file(file_path):
    if os.path.exists(file_path):
        os.remove(file_path)
        print("INFO: %s delete_file: delete file: %s" % (TAG, file_path))
    else:
        print("INFO: %s delete_file: file not exists: %s" % (TAG, file_path))


if __name__ == "__main__":
    # parse command
    env, unit, brand, platform, version, deploy_mode, channel, output_path, debug_enable, scene, bits_publish = parse_argv()
    # fetch script
    script_path = fetch_dynamic_script(DYNAMIC_SCRIPT_URL, version, platform, bits_publish)
    # run script
    command = "%s %s -e %s -u %s -b %s -o %s -v %s -m %s -p %s -s %s -i %s" % \
              (quotes(sys.executable), quotes(script_path), quotes(env), quotes(unit), quotes(brand), platform, quotes(version), deploy_mode, quotes(output_path), scene,
               bits_publish)
    if channel:
        command += " -c %s" % channel
    print("INFO: %s command is: %s" % (TAG, command))
    r = system_run(command)
    # exit when dynamic script failed
    if r != 0:
        sys.exit(-1)
    # delete script
    delete_file(script_path)
