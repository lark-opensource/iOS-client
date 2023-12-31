# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkFeedBanner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkFeedBanner'
  s.version = '5.30.0.5415335'
  s.summary          = 'LarkFeed Banner逻辑抽离'
  s.description      = 'Feed负责Banner布局和动画，LarkFeedBanner负责Banner业务逻辑'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkFeedBanner'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'yuanping.0@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkFeedBanner' => ['resources/*'] ,
      'LarkFeedBannerAuto' => ['auto_resources/*', 'R/**/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RustPB'
  s.dependency 'LarkAccountInterface'
  s.dependency 'RunloopTools'
  s.dependency 'LarkSDKInterface'
  s.dependency 'RxRelay'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'LarkTourInterface'
  s.dependency 'LarkGuide'
  s.dependency 'LarkNavigation'
  s.dependency 'EENotification'
  s.dependency 'UGReachSDK'
  s.dependency 'UGContainer'
  s.dependency 'UGBanner'
  s.dependency 'UGRCoreIntegration'
  s.dependency 'UGRule'
  s.dependency 'LarkIllustrationResource'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkOpenFeed'

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
  s.preserve_paths = 'configurations/**/*'
end
