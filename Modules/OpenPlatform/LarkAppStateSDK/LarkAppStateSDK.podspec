 Pod::Spec.new do |s|
  s.name         = "LarkAppStateSDK"
  s.version      = "3.22.0"
  s.author       = { "luogantong" => "dengdaizerenrentianxie@bytedance.com" }
  s.license      = 'MIT'
  s.homepage     = "https://review.byted.org/admin/projects/ee/LarkAppStateSDK-iOS"
  s.summary      = "LarkAppStateSDK."
  s.description  = 'LarkAppStateSDK for Lark'
  s.source       = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/Lark', :tag => s.version.to_s }
  s.platform = :ios
  s.source_files  = 'src/**/*.swift'
  s.resource_bundles = {
    'LarkAppStateSDK' => ['resources/*'],
    'LarkAppStateSDKAuto' => ['auto_resources/*'],
  }
  s.preserve_paths = 'configurations/**/*'
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.3"

  s.dependency 'EENavigator'
  s.dependency 'LKCommonsTracker'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkActionSheet'
  s.dependency 'LarkAppConfig'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkMessageCore'
  s.dependency 'LarkOPInterface'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'ECOProbe'
  s.dependency 'LarkRustHTTP'
  s.dependency 'RxSwift'
  s.dependency 'SnapKit'
  s.dependency 'SwiftyJSON'
  s.dependency 'Swinject'
  s.dependency 'OPSDK'
  s.dependency 'EEMicroAppSDK'
  s.dependency 'LarkAssembler/default'
  s.dependency 'LarkAssembler/SwinjectBuilder'
  s.dependency 'LarkOpenWorkplace'
end
