# frozen_string_literal: true

#
# Be sure to run `pod lib lint JsSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'JsSDK'
  s.version          = "5.4.0-alpha.1" # 修改版本号需要发版，单品App也依赖此pod
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
  s.swift_version = '5.3'

  # s.public_header_files = 'Pod/Classes/**/*.h'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # JsSDK 自身核心代码 Subspec 拆分详情 https://bytedance.feishu.cn/docs/doccnj9WDuhs2Sf1gwTlARrBKAg
  s.subspec 'Core' do |cs|
    cs.source_files = 'Core/**/*'

    cs.dependency 'WebBrowser'
    cs.dependency 'LarkOPInterface'
    cs.dependency 'Alamofire'
    cs.dependency 'LKCommonsLogging'
    cs.dependency 'RxSwift'
    cs.dependency 'Swinject'

    # LarkWebViewController 和其他 subspec 都有依赖 放在Core
    cs.dependency 'LarkUIKit/Base'
    cs.dependency 'LarkUIKit/Common'
    cs.dependency 'LarkUIKit/LoadPlaceholder'
    cs.dependency 'LarkUIKit/NaviProtocol'
    cs.dependency 'RoundedHUD'
    cs.dependency 'EENavigator'
    cs.dependency 'EcosystemWeb'
  end

  # Base Handlers
  s.subspec 'Base' do |cs|
    cs.source_files = 'Handlers/Base/**/*'
    cs.dependency 'JsSDK/Core'
    cs.dependency 'JsSDK/Resource'

    cs.dependency 'LKCommonsTracker'
    cs.dependency 'LarkAlertController'
    cs.dependency 'ReachabilitySwift'
    cs.dependency 'LarkKeyboardKit'
    cs.dependency 'OPFoundation'
  end

  # Bizs Handlers
  s.subspec 'Bizs' do |cs|
    cs.source_files = 'Handlers/Bizs/**/*'
    cs.dependency 'JsSDK/Core'
    cs.dependency 'JsSDK/Common'
    cs.dependency 'JsSDK/Resource'

    cs.dependency 'RxCocoa'
    cs.dependency 'SwiftyJSON'
    cs.dependency 'EEMicroAppSDK'
    cs.dependency 'LarkOPInterface'
    cs.dependency 'LarkAccountInterface'
    cs.dependency 'LarkAppConfig'
    cs.dependency 'LarkContainer'
    cs.dependency 'LarkFeatureGating'
    cs.dependency 'LarkMessengerInterface'
    cs.dependency 'LarkModel'
    cs.dependency 'LarkNavigation'
    cs.dependency 'LarkRustHTTP'
    cs.dependency 'QRCode'
    cs.dependency 'LarkSDKInterface'
    cs.dependency 'LarkBytedCert'
    cs.dependency 'LarkAccount'
  end
  
  # Common Handlers
  s.subspec 'Common' do |cs|
    cs.source_files = 'Handlers/Common/**/*'
    cs.dependency 'JsSDK/Core'

    cs.dependency 'LarkAppConfig'
    cs.dependency 'LarkAccountInterface'
  end

  # Dynamic Handlers
  s.subspec 'Dynamic' do |cs|
    cs.source_files = 'Handlers/Dynamic/**/*'
    cs.dependency 'JsSDK/Core'
    cs.dependency 'JsSDK/Resource'

    cs.dependency 'LarkAlertController'
    cs.dependency 'LarkFeatureGating'
    cs.dependency 'LarkMessengerInterface'
    cs.dependency 'LarkRustClient'
    cs.dependency 'LarkSnsShare'
    cs.dependency 'LarkAddressBookSelector'
    cs.dependency 'LarkSDKInterface'
    cs.dependency 'EEMicroAppSDK' # 使用了一个颜色便利方法 UIColor(hexString: 后续可以移除  
  end

  # Device Handlers
  s.subspec 'Device' do |cs|
    cs.source_files = 'Handlers/Device/**/*'
    cs.dependency 'JsSDK/Core'
  end

  s.subspec 'Passport' do |cs|
    cs.source_files = 'Handlers/Passport/**/*'
    cs.dependency 'JsSDK/Core'

    cs.dependency 'LarkAccountInterface'
    cs.dependency 'LarkContainer'
    cs.dependency 'LarkReleaseConfig'
  end

  # 资源
  s.subspec 'Resource' do |cs|
    cs.source_files = 'src/configurations/**/*'

    cs.resource_bundles = {
#      'JsSDK' => ['resources/*'] ,
      'JsSDKAuto' => 'auto_resources/*'
    }
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
