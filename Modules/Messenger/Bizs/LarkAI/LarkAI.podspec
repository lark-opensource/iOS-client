# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkAI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkAI'
  s.version = '5.31.0.5464178'
  s.summary          = 'Lark AI相关功能'
  s.description      = '包含消息翻译、图片翻译、网页翻译、Smart Reply等功能'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'zhanghongyun.0729@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkAI' => ['resources/*'] ,
      'LarkAIAuto' => ['auto_resources/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkCore'
  s.dependency 'SnapKit'
  s.dependency 'LarkFeatureGating'
  s.dependency 'RxSwift'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkModel'
  s.dependency 'EENavigator'
  s.dependency 'LarkContainer'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkMenuController'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkMessageBase'
  s.dependency 'WebBrowser'
  s.dependency 'OfflineResourceManager'
  s.dependency 'EditTextView'
  s.dependency 'LarkGuide'
  s.dependency 'LarkGuideUI'
  s.dependency 'CookieManager'
  s.dependency 'Alamofire'
  s.dependency 'LarkRustHTTP'
  s.dependency 'LarkAppConfig'
  s.dependency 'LarkEnv'
  s.dependency 'UniverseDesignCheckBox'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignButton'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'LarkSearchCore'
  s.dependency 'LarkMessageCore'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkForward'
  s.dependency 'LarkOpenChat'
  s.dependency 'LarkKAFeatureSwitch'
  s.dependency 'LarkSensitivityControl/Core'
  s.dependency 'LarkSensitivityControl/API/Pasteboard'
  s.dependency 'LarkSetting'
  s.dependency 'LarkQuickLaunchBar'
  s.dependency 'LarkQuickLaunchInterface'
  s.dependency 'LarkAIInfra'
  s.dependency 'FigmaKit'
  s.dependency 'lottie-ios'
  s.dependency 'SuiteAppConfig'
  s.dependency 'LarkAccountInterface'
  s.dependency 'ESPullToRefresh'

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
