# frozen_string_literal: true

#
# Be sure to run `pod lib lint ByteViewTab.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'ByteViewTab'
  s.version = '5.31.0.5477058'
  s.summary          = 'ByteView独立Tab功能'
  s.description      = 'ByteView独立Tab功能'
  s.homepage         = 'https://code.byted.org/ee/ByteView.iOS/tree/develop/Modules/ByteViewTab'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "kiri": 'dengqiang.001@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'


  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
    'ByteViewTab' => [
      'resources/Images.xcassets', 
      'resources/Lottie/*', 
      'resources/*.xcprivacy'
    ],
    'ByteViewTabAuto' => ['auto_resources/*']
  }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.frameworks = 'EventKit', 'SpriteKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'ByteViewCommon'
  s.dependency 'ByteViewTracker'
  s.dependency 'ByteViewUI'
  s.dependency 'ByteViewSetting'
  s.dependency 'ByteViewNetwork'
  s.dependency 'LarkLocalizations'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignToast'
  s.dependency 'ByteViewUDColor'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'Action'
  s.dependency 'RxDataSources'
  s.dependency 'SnapKit'
  s.dependency 'ESPullToRefresh'
  s.dependency 'LKCommonsLogging'
  s.dependency 'RichLabel'
  s.dependency 'LarkTimeFormatUtils'
  s.dependency 'lottie-ios'
  s.dependency 'ReachabilitySwift'
  s.dependency 'LarkResource'
  s.dependency 'NSObject+Rx'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'LarkIllustrationResource'
  s.dependency 'FigmaKit'

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
