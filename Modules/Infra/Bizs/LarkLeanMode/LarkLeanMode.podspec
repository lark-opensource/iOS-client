# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkLeanMode.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkLeanMode'
  s.version = '5.31.0.5463996'
  s.summary          = '精简模式'
  s.description      = 'Lark Lean Mode'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkLeanMode'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "yuanping": 'yuanping.0@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.1'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkLeanMode' => ['resources/*'] ,
      'LarkLeanModeAuto' => ['auto_resources/*']
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'Swinject'
  s.dependency 'EENavigator'
  s.dependency 'SnapKit'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkAccountInterface'
  s.dependency 'ByteWebImage'
  s.dependency 'LarkRustClient'
  s.dependency 'Homeric'
  s.dependency 'SuiteAppConfig'
  s.dependency 'LarkAvatar'
  s.dependency 'BootManager'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignToast'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkSetting'
  s.dependency 'LarkSceneManager'

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
