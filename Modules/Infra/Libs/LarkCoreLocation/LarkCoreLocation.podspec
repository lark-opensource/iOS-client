# frozen_string_literal: true

#
# Be sure to run `pod lib lint LarkCoreLocation.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name             = 'LarkCoreLocation'
  s.version = '5.31.0.5465592'
  s.summary          = '对定位功能的封装'
  s.description      = '提供定位相关SDK的统一接口&单次定位&持续定位的便捷方法'
  s.homepage         = 'Required. 设置为该Pod所在Repo的URL地址，精确到Pod所在目录'
  
  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "zhangxudong": 'zhangxudong.999@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  # 国内Interface
  s.subspec 'Interface' do |sub|
    sub.source_files = 'src/Source/Interface/**/*.{swift,h,m}'
  end

  # 国际实现
  s.subspec 'InternationalImp' do |sub|
    sub.source_files = 'src/Source/Implementation/**/*.{swift,h,m}'
    sub.dependency 'LarkAssembler'
    sub.dependency 'Swinject'
    sub.dependency 'LarkCoreLocation/Interface'
    sub.dependency 'LarkContainer'
    sub.dependency 'LarkPrivacySetting'
    sub.dependency 'LKCommonsTracker'
    sub.dependency 'Homeric'
    sub.dependency 'LarkSetting'
    sub.dependency 'ThreadSafeDataStructure'
    sub.dependency 'AppReciableSDK'
    sub.dependency 'LarkFeatureGating'
    sub.dependency 'LarkSensitivityControl/API/Location'
  end

  # 国内实现
  s.subspec 'InternalImp' do |sub|
    sub.source_files = 'src/Source/Implementation/**/*.{swift,h,m}'
    sub.dependency 'AMapLocation-NO-IDFA'
    sub.dependency 'AMapFoundation-NO-IDFA'
    sub.dependency 'LarkAssembler'
    sub.dependency 'Swinject'
    sub.dependency 'LarkContainer'
    sub.dependency 'LarkCoreLocation/Interface'
    sub.dependency 'LarkPrivacySetting'
    sub.dependency 'LKCommonsTracker'
    sub.dependency 'Homeric'
    sub.dependency 'LarkSetting'
    sub.dependency 'ThreadSafeDataStructure'
    sub.dependency 'AppReciableSDK'
    sub.dependency 'LarkFeatureGating'
    sub.dependency 'LarkSensitivityControl/API/Location'
  end

  s.frameworks = 'CoreLocation'
  s.default_subspecs = 'Interface'

  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }
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
