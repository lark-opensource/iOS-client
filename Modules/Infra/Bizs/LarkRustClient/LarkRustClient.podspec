Pod::Spec.new do |s|
  s.name          = 'LarkRustClient'
  s.version = '5.29.0.5409259'
  s.author        = { '王孝华' => 'wangxiaohua@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios/LarkRustClient/tree/master/'
  s.summary       = 'LarkRustClient'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkRustClient', :tag => s.version.to_s }
  s.platform      = :ios
  s.ios.deployment_target  = "11.0"
  s.swift_version = "5.1"

  s.subspec 'Interface' do |ss|
    ss.source_files = 'LarkRustClient/Interface/**/*.swift'
    ss.dependency 'RustPB'
    ss.dependency 'RustSDK'
    ss.dependency 'RxSwift'
    ss.dependency 'ServerPB'
    ss.dependency 'LarkCombine'
    ss.dependency 'LarkContainer'
  end

  s.subspec 'Client' do |ss|
    ss.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => ["Client"] }
    ss.source_files = 'LarkRustClient/*.{swift,h}'
    # ss.private_header_files = 'LarkRustClient/*.h'

    ss.dependency  'RustPB'
    ss.dependency  'RustSDK', '>= 3.7.0-alpha'
    ss.dependency  'ReachabilitySwift'
    ss.dependency  'RxSwift'
    ss.dependency  'LKCommonsLogging'
    ss.dependency  'LarkRustClient/Interface'
    ss.dependency  'EEAtomic'
    ss.dependency  'ServerPB'
    ss.dependency  'LarkStorage'
  end

  # 其他的RustFFI接口封装, 避免业务方裸掉C接口，且实现不收敛
  s.subspec 'Other' do |ss|
    ss.source_files = 'LarkRustClient/Other/*.{swift,h}'
    ss.dependency  'RustPB'
    ss.dependency  'RustSDK'
  end

  s.subspec 'Mock' do |ss|
    ss.source_files = 'LarkRustClient/Mock/*.swift'
    ss.dependency 'Socket.IO-Client-Swift', '~> 15.2.0'
    ss.dependency 'LarkRustClient/Client'
  end

  s.default_subspecs = 'Interface', 'Client', 'Other'
end
