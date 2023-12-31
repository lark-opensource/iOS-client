Pod::Spec.new do |s|
  s.name          = 'LarkShareExtension'
  s.version = '5.30.0.5410491'
  s.author        = { 'kkk' => 'kongkaikai@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios/Lark/tree/master/'
  s.summary       = 'Lark Share Extension Assembly'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/Lark', :tag => s.version.to_s }

  s.platform      = :ios
  s.ios.deployment_target = "11.0"
  s.static_framework = true
  s.swift_version = "5.3"

  s.source_files = 'src/**/*.swift'
  s.resource_bundles = {
    'LarkShareExtension' => ['Resources/**/*'], # TODO 移动文件时改成resource, 现在防止和Lark的重命名
    'LarkShareExtensionAuto' => ['auto_resources/*']
  }

  s.dependency 'LarkExtensionCommon'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkExtensionServices/Log'
  # 供ShareExtension依赖，请勿随意添加依赖
end
