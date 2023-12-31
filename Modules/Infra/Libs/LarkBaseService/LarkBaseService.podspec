# coding: utf-8
# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkBaseService.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkBaseService'
  s.version = '5.31.0.5484102'
  s.summary          = 'Required. 一句话描述该Pod功能'
  s.description      = 'Required. 描述该Pod的功能组成等信息'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'email'
  }
  s.platform      = :ios
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  s.subspec 'AppsFlyerFramework' do |cs|
    cs.source_files = 'src/AppsFlyerFramework/**/*.{h,m,mm,swift}'
    cs.dependency 'LarkBaseService/Core'
    cs.dependency 'AppsFlyerFramework'
    cs.dependency 'LarkAccount'
    cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkBaseService_APPSFLYERFRAMEWORK' }
  end

  # s.public_header_files = 'Pod/Classes/**/*.h'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.subspec 'Core' do |cs|
    cs.source_files = 'src/**/*.{h,m,mm,swift}'
    cs.resource_bundles = {
        'LarkBaseService' => ['resources/*'] ,
        'LarkBaseServiceAuto' => 'auto_resources/*'
    }

    cs.dependency 'AppContainer'
    cs.dependency 'BDABTestSDK'
    cs.dependency 'RangersAppLog/Core'
    cs.dependency 'RunloopTools'
    cs.dependency 'LarkReleaseConfig'
    cs.dependency 'Swinject'
    cs.dependency 'Homeric'
    cs.dependency 'RxSwift'
    cs.dependency 'LKCommonsTracker'
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'LarkTracker'
    cs.dependency 'LarkAccountInterface'
    cs.dependency 'LarkAppConfig'
    cs.dependency 'LarkKAFeatureSwitch'
    cs.dependency 'LarkPerf'
    cs.dependency 'LKMetric'
    cs.dependency 'LarkMonitor'
    cs.dependency 'EETroubleKiller'
    cs.dependency 'LarkRustHTTP'
    cs.dependency 'LarkRustClient'
    cs.dependency 'LarkFoundation'
    cs.dependency 'Heimdallr/ALog'
    cs.dependency 'Heimdallr/Monitors'
    cs.dependency 'Heimdallr/TTMonitor'
    cs.dependency 'Heimdallr/NetworkTraffic'
    cs.dependency 'Heimdallr/HMDStart'
    cs.dependency 'Heimdallr/HMDANR'
    cs.dependency 'Heimdallr/HMDWatchDog'
    cs.dependency 'Heimdallr/CrashDetector'
    cs.dependency 'Heimdallr/UserException'
    cs.dependency 'Heimdallr/HMDOOMCrash'
    cs.dependency 'Heimdallr/ALog'
    cs.dependency 'Heimdallr/UIFrozen'
    cs.dependency 'Heimdallr/MemoryGraph'
    cs.dependency 'Logger/Lark'
    cs.dependency 'LarkUIKit'
    cs.dependency 'TTVideoEngine'
    cs.dependency 'TTVideoEditor/Core'
    cs.dependency 'OfflineResourceManager'
    cs.dependency 'LarkDebug'
    cs.dependency 'LarkExtensionCommon'
    cs.dependency 'LarkBGTaskScheduler'
    cs.dependency 'BDDataDecoratorTob'
    cs.dependency 'LarkOrientation'
    cs.dependency 'LarkCanvas'
    cs.dependency 'LarkShareToken'
    cs.dependency 'LarkSnsShare'
    cs.dependency 'BootManager'
    cs.dependency 'LarkResource'
    cs.dependency 'LarkUIExtension'
    cs.dependency 'LarkSafety'
    cs.dependency 'LarkCache'
    cs.dependency 'LarkFileKit'
    cs.dependency 'LarkContainer'
    cs.dependency 'CookieManager'
    cs.dependency 'LarkRustClientAssembly'
    cs.dependency 'UniverseDesignIcon'
    cs.dependency 'LarkAssembler'
    cs.dependency 'LarkSetting'
    cs.dependency 'LarkNotificationServiceExtensionLib'
  end
  
  #s.subspec 'Debug' do |ss|
  #  ss.dependency 'IESGeckoKitDebug'
  #end

  s.default_subspecs = 'Core'

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
