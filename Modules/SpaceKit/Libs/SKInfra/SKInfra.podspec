# frozen_string_literal: true

#
# Be sure to run `pod lib lint SKInfra.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'SKInfra'
  s.version          = '0.1.0-alpha.0'
  s.summary          = 'SpaceKit 业务支持基建组件'
  s.description      = '包含gecko，networting，pasteboard，watermark等'
  s.homepage         = 'ttps://code.byted.org/lark/iOS-client/tree/develop/Modules/SpaceKit/Libs/SKInfra'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "huangzhikai": 'huangzhikai.hzk@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.3'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift,h,m,mm}'
  # s.resource_bundles = {
  #     'SKInfra' => ['resources/*.lproj/*', 'resources/*'],
  #     'SKInfraAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  # }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'LarkLocalizations'
  s.dependency 'SKFoundation'
  s.dependency 'SpaceInterface'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'SKUIKit'
  s.dependency 'LarkEMM'
  s.dependency 'LarkSetting'
  
  
  # React 相关
  s.dependency 'BitableBridge', '2.0.1'
  
  # React-Core
  s.dependency 'React-Core/Default'
  s.dependency 'React-Core/RCTWebSocket'
  # s.dependency 'React-Core/DevSupport', '0.61.2'
  s.dependency 'React-jsi'
  s.dependency 'React-cxxreact'
  s.dependency 'React-jsiexecutor'
  s.dependency 'React-jsinspector'
  
  # React-Core turbo modules
  s.dependency 'React-CoreModules'
  s.dependency 'FBReactNativeSpec'
  s.dependency 'RCTTypeSafety'
  s.dependency 'FBLazyVector'
  s.dependency 'React-RCTImage'
  s.dependency 'RCTRequired'
  s.dependency 'React-RCTNetwork'
  s.dependency 'ReactCommon/turbomodule/core'
  

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
