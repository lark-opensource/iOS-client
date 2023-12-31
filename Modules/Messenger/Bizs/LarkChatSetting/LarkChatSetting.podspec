# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkChatSetting.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkChatSetting'
  s.version = '5.31.0.5477737'
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
  s.swift_version = '5.1'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkChatSetting' => ['resources/*'] ,
      'LarkChatSettingAuto' => 'auto_resources/*'
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'EENavigator'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkActionSheet'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkSetting'
  s.dependency 'LarkBadge'
  s.dependency 'LarkButton'
  s.dependency 'LarkContainer'
  s.dependency 'LarkCore'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkFeatureSwitch'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'LarkModel'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkSDKInterface'
  s.dependency 'LarkTag'
  s.dependency 'LarkUIKit'
  s.dependency 'LKCommonsLogging'
  s.dependency 'QRCode'
  s.dependency 'RichLabel'
  s.dependency 'UniverseDesignToast'
  s.dependency 'RxCocoa'
  s.dependency 'RxRelay'
  s.dependency 'RxSwift'
  s.dependency 'SnapKit'
  s.dependency 'Swinject'
  s.dependency 'LarkSegmentedView'
  s.dependency 'LarkSnsShare'
  s.dependency 'LarkShareToken'
  s.dependency 'ByteDanceKit'
  s.dependency 'SuiteAppConfig'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'AppReciableSDK'
  s.dependency 'LarkMessageCore'
  s.dependency 'LarkOpenChat'
  s.dependency 'LarkKAFeatureSwitch'
  s.dependency 'LarkSceneManager'
  s.dependency 'LarkVideoDirector/CameraKit'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'FigmaKit'
  s.dependency 'LarkAppResources'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'LarkOpenFeed'
  s.dependency 'LarkEMM'
  s.dependency 'LarkOPInterface'
  s.dependency 'LarkBizTag'
  s.dependency 'LarkSensitivityControl/API/Pasteboard'
  s.dependency 'LarkBoxSetting'

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
