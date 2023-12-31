# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkFeedback.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkFeedback'
  s.version          = '4.1.0'
  s.summary          = 'BDFeedBack wrapper'
  s.description      = 'BDFeedBack wrapper, 为了方便使用故而包装成了独立的Pod'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "kongkaikai": 'kongkaikai@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.3'

  s.source_files = 'src/**/*.{swift}'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  s.dependency 'AppContainer'
  s.dependency 'BDFeedBack'
  s.dependency 'BootManager'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkDebugExtensionPoint'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkSuspendable'
  s.dependency 'RxSwift'
  s.dependency 'Swinject'
  s.dependency 'LarkAssembler'
end
