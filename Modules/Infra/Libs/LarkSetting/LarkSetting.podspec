# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSetting.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSetting'
  s.version = '5.31.0.5484102'
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

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.resource_bundles = {
  #     'LarkSetting' => ['resources/*'],
  # }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  s.subspec 'Core' do |sp|
    sp.dependency 'LarkCombine'
    sp.dependency 'RxSwift'
    sp.dependency 'RxCocoa'
    sp.dependency 'LKCommonsLogging'
    sp.dependency 'LKCommonsTracker'
    sp.dependency 'ThreadSafeDataStructure'
    sp.dependency 'LarkCache'
    sp.dependency 'LarkReleaseConfig'
    sp.dependency 'LarkEnv'
    sp.dependency 'LarkContainer'
    sp.dependency 'SnapKit'
    sp.dependency 'LarkDebugExtensionPoint'
    sp.dependency 'EENavigator'
    sp.dependency 'Homeric'
    sp.dependency 'LarkAccountInterface'
    sp.dependency 'LarkFoundation'

    sp.source_files = 'src/Core/**/*.{swift}'
    sp.resource = ['Resources/lark_settings', 'Resources/AutoUserSettingKeys.plist', 'Resources/ManualUserSettingKeys.plist', 'Resources/PrivacyInfo.xcprivacy']
  end

  s.subspec 'LarkAssemble' do |sp|
    sp.dependency 'LarkSetting/Core'
    sp.dependency 'LarkRustClient'
    sp.dependency 'LarkAccountInterface'
    sp.dependency 'BootManager'
    sp.dependency 'LarkAssembler'
    sp.dependency 'LarkRustFG'
    sp.dependency 'LarkStorage'

    sp.source_files = 'src/LarkAssemble/**/*.{swift}'
  end

  s.default_subspec = ['Core']

  attributes_hash = s.instance_variable_get('@attributes_hash')
  
  attributes_hash['extra'] = {
    "git_url": 'Required.'
  }
end
