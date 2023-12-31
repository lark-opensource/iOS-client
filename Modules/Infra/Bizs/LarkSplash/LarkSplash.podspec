# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkSplash.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkSplash'
  s.version = '5.31.0.5475435'
  s.summary          = 'Lark开屏展示'
  s.description      = 'Lark开屏展示'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "wangyuanxun": 'wangyuanxun@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
  s.dependency 'LarkAssembler'

  s.subspec 'common' do |sub|
    sub.source_files = 'src/common/**/*.{swift,h,m}'
    sub.dependency 'BootManager'
    sub.dependency 'ServerPB'
    sub.dependency 'AppContainer'
    sub.dependency 'Swinject'
    sub.dependency 'LarkRustClient'
    sub.dependency 'Homeric'
    sub.dependency 'LKCommonsTracker'
    sub.dependency 'EENavigator'
    sub.dependency 'LarkStorage'
    sub.dependency 'LarkSceneManager'
    sub.dependency 'LarkAccountInterface'
    sub.dependency 'LarkExtensions'
  end

  # 国内的地图依赖配置
  s.subspec 'domestic' do |sub|
    sub.source_files = 'src/domestic/**/*.{swift,h,m}'
    sub.dependency 'TTAdSplashSDK/Core'
    sub.dependency 'LarkSplash/common'
  end
  
  # 海外的地图依赖配置
  s.subspec 'overseas' do |sub|
    sub.source_files = 'src/overseas/**/*.{swift,h,m}'
    sub.dependency 'BDASplashSDKI18N/Core'
    sub.dependency 'LarkSplash/common'
  end

  attributes_hash = s.instance_variable_get('@attributes_hash')
  attributes_hash['extra'] = {
    "git_url": 'Required.'
  }

  s.default_subspecs = ['common']
end
