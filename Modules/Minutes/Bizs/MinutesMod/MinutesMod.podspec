# frozen_string_literal: true

#
# Be sure to run `pod lib lint MinutesMod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'MinutesMod'
  s.version = '5.31.0.5475724'
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
  s.swift_version = '5.0'
  
  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.resource_bundles = {
      'MinutesMod' => ['resources/*.xcprivacy']
  }

  # s.frameworks = 'UIKit', 'MapKit'

  s.subspec 'Core' do |sp|
    sp.source_files = ['src/*.{swift}']
    sp.dependency 'Swinject'
    sp.dependency 'LarkFeatureGating'
    sp.dependency 'EENavigator'
    sp.dependency 'LarkFoundation'
    sp.dependency 'LarkUIKit'
    sp.dependency 'LarkRustClient'
    sp.dependency 'LarkTab'
    sp.dependency 'LarkNavigation'
    sp.dependency 'LarkRustHTTP'
    sp.dependency 'LarkTTNetInitializor'
    sp.dependency 'Minutes'
    sp.dependency 'MinutesDependency'
    sp.dependency 'LarkLocalizations'
    sp.dependency 'LarkAssembler'
  end
  
  s.if_pod 'MessengerMod' do |cs|
    cs.dependency 'MinutesDependency/MessengerMod'
  end
  
  s.if_pod 'CCMMod' do |cs|
    cs.dependency 'MinutesDependency/CCMMod'
  end
  
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
