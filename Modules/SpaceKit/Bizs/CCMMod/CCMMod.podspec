# frozen_string_literal: true

#
# Be sure to run `pod lib lint CCMMod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'CCMMod'
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


  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  eval `curl -s http://tosv.byted.org/obj/ee-infra-ios/if_pod_dsl.rb` unless $if_pod_dsl_loaded

  s.subspec 'Core' do |cs|
    cs.dependency 'LarkLocalizations'
    cs.dependency 'SnapKit'
    cs.dependency 'RxSwift'
    cs.dependency 'RxCocoa'
    cs.dependency 'LarkFoundation'
    cs.dependency 'LarkUIKit'
    cs.dependency 'LarkModel'
    cs.dependency 'LarkRustClient'
    cs.dependency 'Swinject'
    cs.dependency 'LarkContainer'
    cs.dependency 'Alamofire'
    cs.dependency 'SpaceKit'
    cs.dependency 'SKBitable'
    cs.dependency 'SKResource'
    cs.dependency 'EENavigator'
    cs.dependency 'SSZipArchive'
    cs.dependency 'smash/qrcode'
    cs.dependency 'LarkAppResources'
    cs.dependency 'LarkRustHTTP'
    cs.dependency 'AsyncComponent'
    cs.dependency 'SpaceInterface'
    cs.dependency 'LarkCustomerService'
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'LarkPerf'
    cs.dependency 'LarkKeyboardKit'
    cs.dependency 'LarkAppConfig'
    cs.dependency 'LarkDebugExtensionPoint'
    cs.dependency 'AppContainer'
    cs.dependency 'LarkNavigator'
    cs.dependency 'LarkNavigation'
    cs.dependency 'LarkAppLinkSDK'
    cs.dependency 'LarkLeanMode'
    cs.dependency 'BootManager'
    cs.dependency 'CookieManager'
    cs.dependency 'LarkWaterMark'
    cs.dependency 'LarkOpenChat'
    cs.dependency 'UniverseDesignColor'
    cs.dependency 'UniverseDesignEmpty'
    cs.dependency 'UniverseDesignIcon'
    cs.dependency 'UniverseDesignCheckBox'
    cs.dependency 'LarkSecurityComplianceInfra'
    cs.dependency 'LarkSecurityCompliance'
    cs.dependency 'LarkSetting'
    cs.dependency 'OPSDK'
    cs.dependency 'LarkAssembler'
    cs.dependency 'LarkSplitViewController'
    cs.dependency 'QRCode'
    cs.dependency 'LarkBizTag'
    cs.dependency 'LarkOpenFeed'
    cs.dependency 'LarkAIInfra'
    cs.dependency 'WebAppContainer'
    cs.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
    cs.resource_bundles = {
      'CCMMod' => ['resources/*.lproj/*', 'resources/*'],
      'CCMModAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  }
  end

  s.if_pod 'MessengerMod' do |cs|
     cs.dependency 'LarkCore'
     cs.dependency 'LarkMessengerInterface'
     cs.dependency 'LarkSearchFilter'
     cs.dependency 'LarkSearchCore'
     cs.dependency 'LarkSearch'
     cs.dependency 'LarkSDKInterface'
     cs.dependency 'LarkSendMessage'
     cs.dependency 'LarkQRCode'
     cs.dependency 'LarkFeedBase'
     cs.dependency 'LarkAccountInterface'
     cs.dependency 'LarkSceneManager'
     cs.dependency 'Homeric'
     cs.dependency 'LKCommonsTracker'
     cs.dependency 'LarkBizAvatar'
  end
  
  s.if_pod 'TodoMod' do |cs|
     cs.dependency 'TodoInterface'
  end

  s.if_pod 'ByteViewMod' do |cs|
    cs.dependency 'ByteViewInterface'
  end
  s.if_pod 'LarkMail' do |cs|
    cs.dependency 'LarkMailInterface'
  end


  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  # s.resource_bundles = {
  #     'CCMMod' => ['resources/*.lproj/*', 'resources/*'],
  #     'CCMModAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  # }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  # s.dependency 'LarkLocalizations'

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
