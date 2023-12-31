#
# Be sure to run `pod lib lint LarkRustHTTP.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LarkRustHTTP'
  s.version          = '0.25.0'
  s.summary          = 'LarkRustHTTP EE iOS SDK组件'
  s.description      = '替换HTTP底层实现，可方便的导流到其它传输层如Rust'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/LarkRustHTTP'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { '王孝华' => 'wangxiaohua@bytedance.com' }
  s.source           = { git: 'ssh://git.byted.org:29418/ee/EEScaffoldd' }
  s.ios.deployment_target = '11.0'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.swift_version = '5.1'
  # s.resource_bundles = {
  #     'LarkRustHTTP' => ['resources/*'] ,
  #     'LarkRustHTTPAuto' => 'auto_resources/*'
  # }
  s.subspec 'Core' do |ss|
    # RustHTTP encapsulate
    ss.source_files = 'src/*.{swift,h,m,mm,cpp}'
    ss.exclude_files = 'src/{RustHttpURLProtocol,WK,Web}*.swift'
    ss.dependency 'RustPB', '>= 2.6.0-alpha'
    ss.dependency 'LKCommonsLogging'
    ss.dependency 'LarkRustClient'
    ss.dependency 'EEAtomic'
  end

  s.subspec 'URLProtocol' do |ss|
    # 使用URLProtocol实现导流，和系统API, 三方组件兼容性好，改动成本低
    ss.source_files = 'src/RustHttpURLProtocol*.swift'
    ss.dependency 'LarkRustHTTP/Core'
    ss.dependency 'HTTProtocol'
  end
  s.subspec 'WebView' do |ss|
    ss.source_files = 'src/{Web,WK}*.swift'
    ss.dependency 'LarkRustHTTP/URLProtocol'
  end
  s.subspec 'Session' do |ss|
    # 直接调用RustHTTP，避免URLSession额外的protocol线程限制。
    ss.source_files = 'src/Session/*.swift'
    ss.dependency 'LarkRustHTTP/URLProtocol'
  end

  attributes_hash = s.instance_variable_get(:@attributes_hash)
  # setup bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
    bot: '41868977bb984eb08f19d9ee38e0349b'
  }
end
