# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkFlag.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkFlag'
  s.version = '5.31.0.5470696'
  s.summary          = '标记模块'
  s.description      = '对Feed、Message标记操作和展示列表'
  s.homepage         = 'https://code.byted.org/lark/Lark-Messenger/tree/develop/Bizs/LarkFlag'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'qujieye@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  s.source_files = 'src/**/*.{swift,h,m,c}'
  s.resource_bundles = {
      'LarkFlag' => ['resources/*'] ,
      'LarkFlagAuto' => ['auto_resources/*'],
  }
  s.preserve_paths = 'configurations/**/*'


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'LarkLocalizations'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'LarkSwipeCellKit'
  s.dependency 'LarkModel'
  s.dependency 'LarkMessageCore'
  s.dependency 'LarkOpenFeed'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkContainer'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkCore'
  s.dependency 'LarkChat'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkSDKInterface'
  s.dependency 'LarkContainer'
  s.dependency 'LKCommonsLogging'
  s.dependency 'RustPB'
  s.dependency 'ServerPB'
  s.dependency 'TangramService'
  s.dependency 'EENavigator'
  s.dependency 'Homeric'
  s.dependency 'SnapKit'
  s.dependency 'Swinject'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxDataSources'
  s.dependency 'RxRelay'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignToast'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignIcon'

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
