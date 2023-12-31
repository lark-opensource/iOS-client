# coding: utf-8
Pod::Spec.new do |s|
  s.name          = 'LarkTracker'
  s.version = '5.30.0.5441697'
  s.author        = { 'LiChen' => 'lichen.arthur@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkTracker'
  s.summary       = '头条打点封装'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkBusinessModule', :tag => s.version.to_s }
  s.source_files  = 'src/**/*.{swift,h,m}'
  s.platform      = :ios
  s.ios.deployment_target = "12.0"
  s.resource_bundles = {
    'LarkTracker' => ['resources/*']
  }

  s.dependency 'RangersAppLog/Core'
  s.dependency 'RangersAppLog/Filter'
  s.dependency 'TTNetworkManager'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkCache'
  s.dependency 'LKCommonsLogging'
  s.dependency 'CryptoSwift'
  s.dependency 'LarkDebugExtensionPoint'
  s.dependency 'LarkAppLog'
  s.dependency 'RxSwift'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'OneKit/BaseKit'
  s.dependency 'OneKit/Reachability'
  s.dependency 'OneKit/StartUp'
  s.dependency 'OneKit/Service'
  s.dependency 'LarkSetting'
end
