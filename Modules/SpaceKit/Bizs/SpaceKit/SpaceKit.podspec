# frozen_string_literal: true

#
# Be sure to run `pod lib lint SpaceKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name = 'SpaceKit'
  s.version = '5.31.0.5341924'
  s.summary = 'SpaceKit 接入层'
  s.description = '位于顶层，其他业务引用 SpaceKit 时直接引用该库即可'
  s.homepage = 'https://code.byted.org/ee/spacekit-ios/tree/develop/Bizs/SpaceKit'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "lijuyou": 'lijuyou@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.3'


  s.preserve_paths = ['Scripts', 'SpaceKit.podspec']

  # s.public_header_files = 'Pod/Classes/**/*.h'
#  s.resource_bundles = {
#      'SpaceKit' => ['resources/*.lproj/*' 'resources/*'] ,
#      'SpaceKitAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
#  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'SKFoundation'
  s.dependency 'SKUIKit'
  s.dependency 'SKCommon/Core'
  # s.dependency 'SKECM'
  s.dependency 'SKSpace'
  s.dependency 'SKDrive'
  s.dependency 'SKBrowser'
  s.dependency 'SKDoc'
  s.dependency 'SKWikiV2'
  s.dependency 'SKSheet'
  s.dependency 'SKBitable'
  s.dependency 'SKMindnote'
  s.dependency 'SKResource'
  s.dependency 'SKComment'
  s.dependency 'SKPermission'
  s.dependency 'SKWorkspace'
  s.dependency 'LarkSplitViewController'
  s.dependency 'LarkCache'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'LarkAlertController'
  s.dependency 'SKSlides'

  s.subspec 'Core' do |ss|
    ss.source_files = 'src/**/*.{swift,h,m,mm,cpp,xib}'
  end

  s.subspec 'LarkEditorJS' do |ss|
    ss.dependency 'LarkEditorJS'
    ss.pod_target_xcconfig	=  { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D SK_EDITOR_JS' }
  end
  
  s.xcconfig = {
    'ENABLE_BITCODE' => 'NO',
    'OTHER_LDFLAGS' => '-ObjC -weak_framework CryptoKit'
  }

  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_HAS_CODEC=1'
  }

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'git@code.byted.org:ee/spacekit-ios.git'
  }

end
