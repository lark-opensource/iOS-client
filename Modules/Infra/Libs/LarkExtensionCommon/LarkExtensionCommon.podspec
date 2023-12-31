Pod::Spec.new do |s|
  s.name          = 'LarkExtensionCommon'
  s.version = '5.31.0.5451694'
  s.author        = { 'Kong kaikai' => 'kongkaikai@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/Bizs/LarkExtensionCommon'
  s.summary       = 'share扩展相关'
  s.source        = { :git => '', :tag => s.version.to_s }

  s.platform      = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.3"

  s.source_files = 'LarkExtensionCommon/Source/**/*.swift'

  s.dependency 'LarkStorageCore'
  # 供Extension与Lark共享数据，请勿随意添加依赖
end
