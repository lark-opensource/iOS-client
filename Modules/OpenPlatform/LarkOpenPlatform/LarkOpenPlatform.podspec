# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkOpenPlatform.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

# 引入if_pod语法扩展
eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkOpenPlatform'
  s.version = '5.31.0.5454779'
  s.summary          = '开放平台'
  s.description      = '承载开放平台的对外接口和公共逻辑'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkOpenPlatform'
  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'yinhao@bytedance.com'
  }
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.3"
  s.default_subspecs = ['Core']
  s.resource_bundles = {
      'LarkOpenPlatform' => ['resources/*'] ,
      'LarkOpenPlatformAuto' => 'auto_resources/*'
  }
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

  s.if_pod 'CCMMod' do |sp|
    sp.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'CCMMod'}
    sp.dependency 'SpaceInterface'
  end

  s.if_pod 'MessengerMod' do |sp|
    sp.dependency 'LarkOpenFeed'
    sp.dependency 'LarkFeedBase'
    sp.dependency 'LarkMessengerInterface'
    sp.dependency 'LarkBizTag'
  end
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'src/**/*.{swift}'
    ss.exclude_files = 'src/NativeApp/**/*.{swift}'
    ss.dependency 'Alamofire'
    ss.dependency 'LarkMessageBase'
    ss.dependency 'AppContainer'
    ss.dependency 'EEMicroAppSDK'
    ss.dependency 'EENavigator'
    ss.dependency 'LarkAccountInterface'
    ss.dependency 'LarkMessengerInterface'
    ss.dependency 'LarkAppConfig'
    ss.dependency 'LarkAppLinkSDK'
    ss.dependency 'LarkAppStateSDK'
    ss.dependency 'LarkFeatureGating'
    ss.dependency 'LarkRustClient'
    ss.dependency 'LarkUIKit'
    ss.dependency 'NewLarkDynamic'
    ss.dependency 'RunloopTools'
    ss.dependency 'LarkModel'
    ss.dependency 'RustPB'
    ss.dependency 'RxSwift'
    ss.dependency 'SnapKit'
    ss.dependency 'Swinject'
    ss.dependency 'BootManager'
    ss.dependency 'LKTracing'
    ss.dependency 'WebBrowser'
    ss.dependency 'JsSDK'
    ss.dependency 'LarkCore'
    ss.dependency 'OPGadget'
    ss.dependency 'OPSDK'
    ss.dependency 'OPFoundation'
    ss.dependency 'LarkShareContainer'
    ss.dependency 'LarkForward'
    ss.dependency 'LarkSnsShare'
    ss.dependency 'Homeric'
    ss.dependency 'ECOInfra'
    ss.dependency 'ECOProbe'
    ss.dependency 'LarkMicroApp'
    ss.dependency 'LarkLocationPicker'
    ss.dependency 'LarkBytedCert'
    ss.dependency 'LarkEditorJS'
    ss.dependency 'LarkNavigator'
    ss.dependency 'LarkWaterMark'
    ss.dependency 'SpaceInterface'
    ss.dependency 'OPPlugin'
    ss.dependency 'LarkSDKInterface'
    ss.dependency 'LarkSendMessage'
    ss.dependency 'UniverseDesignDialog'
    ss.dependency 'LarkGuide'
    ss.dependency 'EcosystemWeb'
    ss.dependency 'OPWebApp'
    ss.dependency 'FigmaKit'
    ss.dependency 'LarkContainer'
    ss.dependency 'UniverseDesignToast'
    ss.dependency 'LarkAssembler'
    ss.dependency 'LKLoadable'
    ss.dependency 'LarkChat'
    ss.dependency 'LarkSetting'
    ss.dependency 'LarkCoreLocation'
    ss.dependency 'UniverseDesignEmpty'
    ss.dependency 'LarkEMM'
    ss.dependency 'LarkOPInterface'
    ss.dependency 'LKCommonsLogging'
    ss.dependency 'LarkMessageCard'
    ss.dependency 'LarkFlag'
    ss.dependency 'OPPlugin'
    ss.dependency 'LarkBoxSetting'
    ss.dependency 'LarkQuickLaunchInterface'
    ss.dependency 'RxRelay'
    ss.dependency 'LarkOpenWorkplace'

    ss.dependency 'RenderRouterInterface'
    ss.dependency 'UniversalCard'
    ss.dependency 'UniversalCardInterface'

    ss.if_pod 'MeegoMod' do |cs|
      cs.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'MeegoMod' }
      cs.dependency 'LarkMeegoInterface'
    end
  end
  
  s.subspec 'NativeApp' do |ss|
    ss.dependency 'NativeAppPublicKit'
    ss.source_files = 'src/NativeApp/**/*.{swift}'
    ss.pod_target_xcconfig = {'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'NativeApp'}
  end
  

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
