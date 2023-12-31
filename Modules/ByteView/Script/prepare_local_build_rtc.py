import os
import re
import argparse
from enum import Enum


class Strategy(Enum):
    REPLACE = 0,
    APPEND = 1


byteview_podspec_path = '/Modules/ByteView/ByteView.podspec'
byteview_podspec_rule = \
    [
        {
            'pattern': 'cs.dependency' + '\'ByteRtcSDK\'' + '.*',
            'strategy': Strategy.REPLACE,
            'use': '    cs.dependency \'ByteRtcEngineKit\'\n' +
                   '    cs.dependency \'ByteSocketIO\'\n' +
                   '    cs.dependency \'SSZipArchive\'\n'
        }
    ]


byteview_example_podfile_path = '/Example/Podfile'
byteview_example_podfile_rule = \
    [
        {
            'pattern': 'pod' + '\'ByteRtcSDK\'' + ',' + '\'.*\'$',
            'strategy': Strategy.REPLACE,
            'use': '  pod \'ByteRtcEngineKit\', :path => "#{ENV[\'RTC_IOS_ROOT\']}/ByteRtcEngineKitLocalDebug.podspec"\n' +
                   '  pod \'ByteSocketIO\', :path => "#{ENV[\'RTC_IOS_ROOT\']}/ByteSocketIOLocalDebug.podspec"\n' +
                   '  pod \'SSZipArchive\', \'2.2.2\'\n'
        },
        {
            'pattern': 'dynamic_frameworks' + '.*' + '\'ByteRtcSDK\'' + '.*',
            'strategy': Strategy.REPLACE,
            'use': 'dynamic_frameworks = [\'CryptoSwift\',\'SSZipArchive\',\'webrtc_ios_pod\',\'ByteRtcEngineKit\',\'ByteSocketIO\']\n'
        },
        {
            'pattern': 'target.build_configurations.each' + 'do' + '\\|config\\|',
            'strategy': Strategy.APPEND,
            'use': '      config.build_settings[\'ENABLE_BITCODE\'] = \'NO\'\n'
        }
    ]


lark_podfile_path = '/Podfile'
lark_podfile_rule = \
    [
        {
            'pattern': 'pod' + '\'ByteView\'' + '.*' + 'subspecs' + '.*',
            'strategy': Strategy.REPLACE,
            'use': '  pod \'ByteView\', :path => "#{ENV[\'BYTEVIEW_ROOT\']}/Modules/ByteView", :subspecs => [\'Debug\', \'Core\'], **byteview_feature\n'
        },
        {
            'pattern': 'pod' + '\'ByteRtcSDK\'' + ',' + '\'.*\'$',
            'strategy': Strategy.REPLACE,
            'use': '  pod \'ByteRtcEngineKit\', :path => "#{ENV[\'RTC_IOS_ROOT\']}/ByteRtcEngineKitLocalDebug.podspec"\n' +
                   '  pod \'ByteSocketIO\', :path => "#{ENV[\'RTC_IOS_ROOT\']}/ByteSocketIOLocalDebug.podspec"\n'
        },
        {
            'pattern': 'force_use_static_framwork' + '.*' + 'except' + '.*',
            'strategy': Strategy.APPEND,
            'use': '    \'ByteRtcEngineKit\', \'ByteSocketIO\', \'SSZipArchive\',\n'
        },
        {
            'pattern': 'pod_target_xcconfig' + '.*' + 'attributes_hash' + '.*',
            'strategy': Strategy.APPEND,
            'use': '    pod_target_xcconfig[\'ENABLE_BITCODE\'] = \'NO\'\n'
        }
    ]


lark_larkvoip_podspec_path = '/Bizs/LarkVoIP/LarkVoIP.podspec'
lark_larkvoip_podspec_rule = [
        {
            'pattern': 's.dependency' + '\'ByteRtcSDK\'' + '.*',
            'strategy': Strategy.REPLACE,
            'use': '  s.dependency \'ByteRtcEngineKit\'\n' +
                   '  s.dependency \'ByteSocketIO\'\n' +
                   '  s.dependency \'SSZipArchive\'\n'
        }
    ]


lark_larkvoip_crptor_h_path = '/Bizs/LarkVoIP/src/VoIP/Cryptor.h'
lark_larkvoip_crptor_h_rule = [
        {
            'pattern': '#import' + '<ByteRtcEngineKit/ByteRtcEngineKit.h>',
            'strategy': Strategy.REPLACE,
            'use': '#import <ByteRtcEngineKit/ByteRtcEngineKit-umbrella.h>\n'
        }
    ]


def read_env_value(key):
    value = os.environ.get(key)
    print('%s = %s' % (key, value))
    return value


def update_file(file_name, rules):
    if not os.path.exists(file_name):
        print('file %s not found' % file_name)
        return

    rfile = open(file_name, 'r')
    lines = rfile.readlines()
    newlines = list()
    for line in lines:
        newline = line
        for rule in rules:
            pattern = rule['pattern']
            strategy = rule['strategy']
            use = rule['use']

            if re.match(pattern, re.sub('\\s+', '', line)):  # 移除空白字符再比较， 这样正则可以写简单点
                if strategy == Strategy.REPLACE:
                    newline = use
                elif strategy == Strategy.APPEND:
                    newline = line + use
            else:
                pass
        newlines.append(newline)
    rfile.close()

    wfile = open(file_name, 'w')
    for line in newlines:
        wfile.write(line)
    wfile.close()


def rename_boringssl_lib():
    rtc_ios_root = read_env_value('RTC_IOS_ROOT')
    if not rtc_ios_root:
        print('error: cannot read env \'RTC_IOS_ROOT\'')
        return

    path = '/ByteSocketIO/third_party/lib/'
    old_name = 'libboringssl.a'
    new_name = 'libboringssl_renamed.a'

    old = rtc_ios_root + path + old_name
    new = rtc_ios_root + path + new_name
    if os.path.exists(old):
        os.rename(old, new)


def update_files_for_byteview():
    byteview_root = read_env_value('BYTEVIEW_ROOT')
    if not byteview_root:
        print('error: cannot read env \'BYTEVIEW_ROOT\'')
        return
    update_file(byteview_root + byteview_podspec_path, byteview_podspec_rule)
    update_file(byteview_root + byteview_example_podfile_path, byteview_example_podfile_rule)


def update_files_for_lark():
    lark_root = read_env_value('LARK_ROOT')
    if not lark_root:
        print('error: cannot read env \'LARK_ROOT\'')
        return
    update_file(lark_root + lark_podfile_path, lark_podfile_rule)
    update_file(lark_root + lark_larkvoip_podspec_path, lark_larkvoip_podspec_rule)
    update_file(lark_root + lark_larkvoip_crptor_h_path, lark_larkvoip_crptor_h_rule)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--byteview', action='store_true', default=True, dest='byteview', help='prepare uild byteview')
    parser.add_argument('--lark', action='store_true', default=False, dest='lark', help='prepare build lark')
    args = parser.parse_args()

    if args.lark:
        rename_boringssl_lib()        # 需要重命名 libboringssl.a 否则会和 lark 里面依赖的同名库冲突
        update_files_for_byteview()   # 编译 lark 也需要 byteview 的适配改动
        update_files_for_lark()
    else:
        update_files_for_byteview()
        pass


if __name__ == "__main__":
    main()
