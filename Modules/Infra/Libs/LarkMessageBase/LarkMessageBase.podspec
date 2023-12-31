# coding: utf-8
#
# Be sure to run `pod lib lint LarkMessageBase.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = "LarkMessageBase"
  s.version = '5.31.0.5470696'
  s.summary          = "Lark消息相关基础模块"
  s.description      = "Lark消息相关基础模块，提供相关接口和基础能力"
  s.homepage         = 'ssh://liuwanlin@git.byted.org:29418/ee/lark/ios-client'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors           = {
    "liuwanlin": "liuwanlin@bytedance.com"
  }

  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'src/**/*.{swift}'
  s.resource_bundles = {
      'LarkMessageBase' => ['resources/*'] ,
      'LarkMessageBaseAuto' => 'auto_resources/*'
  }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { :git => 'generated_by_eesc.zip', :tag => s.version.to_s}

  s.dependency 'LarkLocalizations'
  s.dependency 'AsyncComponent'
  s.dependency 'EEFlexiable'
  s.dependency 'LarkModel'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'Swinject'
  s.dependency 'EETroubleKiller'
  s.dependency 'EENavigator'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkFeatureGating'
  s.dependency 'EEImageMagick'
  s.dependency 'LarkInteraction'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkContainer'
  s.dependency 'LKLoadable'
  s.dependency 'LarkSetting'
  s.dependency 'LKCommonsLogging'

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  #attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  #}
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": "ssh://liuwanlin@git.byted.org:29418/ee/lark/ios-client"
  }
end
