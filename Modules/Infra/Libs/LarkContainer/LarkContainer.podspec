Pod::Spec.new do |s|
  s.name = 'LarkContainer'
  s.version = '5.31.0.5463996'
  s.author        = { 'Jia Chuanqing' => 'jiachuanqing@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios/LarkContainer/tree/master/'
  s.summary       = 'Lark Component Container'
  s.source        = { git: 'ssh://git.byted.org:29418/ee/lark/ios/LarkContainer', tag: s.version.to_s }

  s.platform      = :ios
  s.ios.deployment_target = '11.0'
  s.static_framework = true
  s.swift_version = '5.0'

  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'Swinject'
  s.dependency 'EEAtomic'

  s.source_files = 'src/**/*.swift'
end
