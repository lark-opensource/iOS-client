# frozen_string_literal: true

#
# Be sure to run `pod lib lint SpaceInterface.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name = 'SpaceInterface'
  s.version = '5.31.0.5424672'
  s.summary = 'SpaceKit Interface'
  s.description = 'SpaceKit 对外提供的接口代码，里面只有接口，具体实现在其他业务模块中'
  s.homepage = 'https://code.byted.org/ee/spacekit-ios/tree/develop/Bizs/SpaceInterface'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "lijuyou": 'lijuyou@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.3'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  # s.resource_bundles = {
  #     'SpaceInterface' => ['resources/*.lproj/*' 'resources/*'] ,
  #     'SpaceInterfaceAuto' => ['auto_resources/*.lproj/*', 'auto_resources/*', 'R/**/*']
  # }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  s.dependency  'EENavigator'
  s.dependency  'RxSwift'
  s.dependency  'SwiftyJSON'
  s.dependency  'ReSwift'
  s.dependency  'RxCocoa'
  s.dependency  'RxRelay'
  s.dependency  'LarkLocalizations'
  s.dependency  'LarkRustHTTP'
  s.dependency  'LarkWebViewContainer'
  s.dependency  'LarkDocsIcon'
  # 权限 SDK 的定义依赖了安全合规的 FileBizDomain，目前 LarkMessengerInterface 也是直接依赖，后续有需要再抽离
  s.dependency  'LarkSecurityComplianceInterface'
  s.dependency  'LarkModel'
  s.dependency  'UniverseDesignToast'
  s.dependency  'LarkAIInfra'


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
