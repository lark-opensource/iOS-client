# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkMonitor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkMonitor'
  s.version = '5.31.0.5483823'
  s.summary          = 'app monitor'
  s.description      = 'app monitor'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/LarkMonitor'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'kangtao'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift,h,mm,m,c}'
  s.resource_bundles = {
      'LarkMonitorAuto' => ['auto_resources/**/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'DateToolsSwift'
  s.dependency 'RxCocoa'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'RxSwift'
  s.dependency 'Heimdallr/TTMonitor'
  s.dependency 'Heimdallr/CrashDetector'
  s.dependency 'Heimdallr/UserException'
  s.dependency 'Heimdallr/BootingProtect'
  s.dependency 'Heimdallr/OpenTracing'
  s.dependency 'Heimdallr/HMDLaunchTracing'
  s.dependency 'Heimdallr/ALog'
  s.dependency 'Heimdallr/UIFrozen'
  s.dependency 'BDFishhook'
  s.dependency 'Swinject'
  s.dependency 'RustPB'
  s.dependency 'LarkAlertController'
  s.dependency 'EENavigator'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkContainer'
  s.dependency 'Homeric'
  s.dependency 'LarkKeyboardKit'
  s.dependency 'BootManager'
  # s.dependency 'LarkOpenTrace'
  s.dependency 'LKLoadable'
  s.dependency 'LarkDebugExtensionPoint'
  s.dependency 'LarkSetting'
  s.dependency 'LarkSecurityAudit'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkAssembler'
  s.dependency 'Stinger'
  s.dependency 'TTNetworkManager'
  s.dependency 'LarkEMM'
  s.dependency 'KVOController'
  s.dependency 'Heimdallr/UITracker'
  s.dependency 'Heimdallr/GPUUsage'
  s.dependency 'TTReachability'
  s.dependency 'LarkSensitivityControl/API/DeviceInfo'
  s.dependency 'LarkSensitivityControl/API/Pasteboard'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkCompatible'

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'Required.'
  }
end
