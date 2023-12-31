# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkShareToken.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkShareToken'
  s.version = '5.30.0.5410491'
  s.summary          = 'Lark 分享口令模块'
  s.description      = 'Lark 分享口令模块'
  s.homepage         = 'ios-infra'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "赵冬": 'zhaodong.23@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.resource_bundles = {
      'LarkShareToken' => ['resources/*'],
      'LarkShareTokenAuto' => ['auto_resources/*']
  }

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # =================== 由于安全合规问题，暂时关闭分享口令功能，因此这里去掉对相关代码的依赖配置 ======================

  # # 国内的依赖配置
  # s.feature 'InternalDependency' do |cs|
  #   cs.dependency 'LarkShareToken/internal'
  #   cs.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-D LarkShareToken_Internal' }
  # end

  # s.subspec 'internal' do |sub|
  #   sub.source_files = 'src/internal/**/*.{swift,h,m}'

  #   sub.dependency 'LarkShareToken/configurations'
  #   sub.dependency 'LarkRustClient'
  #   sub.dependency 'LarkUIKit'
  #   sub.dependency 'Swinject'
  #   sub.dependency 'LKCommonsLogging'
  #   sub.dependency 'SnapKit'
  #   sub.dependency 'EENavigator'
  #   sub.dependency 'LarkFeatureGating'
  #   sub.dependency 'LarkModel'
  #   sub.dependency 'EEImageService'
  #   sub.dependency 'LKCommonsTracker'
  #   sub.dependency 'Homeric'
  #   sub.dependency 'LarkAlertController'
  #   sub.dependency 'LarkAccountInterface'
  # end

  s.subspec 'configurations' do |sub|
    sub.source_files = 'src/configurations/**/*.{swift,h,m}'
    sub.dependency 'LarkLocalizations'
  end

  s.subspec 'base' do |sub|
    sub.source_files = 'src/base/**/*.{swift,h,m}'
  end

  s.default_subspecs = ['base']

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
