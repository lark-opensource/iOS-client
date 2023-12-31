Pod::Spec.new do |s|
  s.name          = 'LarkGuide'
  s.version = '5.30.0.5428090'
  s.author        = { 'Yang Jing' => 'yangjing.sniper@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/Lark/iOS/LarkGuide/tree/master/'
  s.summary       = 'National Instruction for Lark'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/Lark/iOS/LarkGuide', :tag => s.version.to_s }
  s.source_files  = 'LarkGuide/**/*.{swift,h,m}'
  s.platform      = :ios
  s.ios.deployment_target = '11.0'
  s.static_framework = true
  s.swift_version = '5.1'

  s.dependency 'LarkUIKit'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkContainer'
  s.dependency 'Swinject'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkGuideUI'
  s.dependency 'LarkAccountInterface'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'Homeric'
  s.dependency 'KeychainAccess'
  s.dependency 'LarkDebug'
  s.dependency 'LarkActionSheet'
  s.dependency 'AppReciableSDK'
  s.dependency 'UniverseDesignColor'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkExtensions'
end
