Pod::Spec.new do |s|
  s.name             = "LarkAppResources"
  s.version = "3.38.1"
  s.summary          = '存放需国际化处理的images'
  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/Bizs/LarkAppResources'
  s.license          = 'MIT'
  s.author           = { "kongkaikai" => "kongkaikai@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.resource_bundles = {
      'LarkAppResources' => 'app_resources/*'
  }
  s.dependency 'LarkResource'
  s.dependency 'LarkSetting'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkContainer'
  s.dependency 'LarkAccountInterface'
  s.dependency 'UniverseDesignTheme'
end
