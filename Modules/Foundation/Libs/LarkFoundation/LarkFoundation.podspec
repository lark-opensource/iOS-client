# coding: utf-8
Pod::Spec.new do |s|
  s.name          = 'LarkFoundation'
  s.version       = '6.0.1'
  s.author        = { 'Li Yuguo' => 'liyuguo.jeffrey@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios/LarkFoundation/tree/master/'
  s.summary       = '通用基础库：WrappedError、Extensions、File、Utils'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkFoundation', :tag => s.version.to_s }
  s.platform      = :ios
  s.ios.deployment_target = '11.0'
  s.swift_version = '5.5'

  s.subspec 'Resource' do |sub|
    sub.source_files = 'LarkFoundation/Resource/*.{swift,h,m}'
    sub.dependency 'LarkFoundation/Extensions'
  end

  s.subspec 'Error' do |sub|
    sub.source_files = 'LarkFoundation/Error/*.{swift}'
  end

  s.subspec 'File' do |sub|
    sub.source_files = 'LarkFoundation/File/*.{swift}'
  end

  s.subspec 'Extensions' do |sub|
    sub.source_files = 'LarkFoundation/Extensions/*.{swift}'
  end

  s.subspec 'Utils' do |sub|
    sub.source_files = 'LarkFoundation/Utils/*.{swift,h,m}'
    sub.dependency 'LarkFoundation/Extensions'
  end

  s.subspec 'FuncContext' do |sub|
    sub.source_files = 'LarkFoundation/Context/*.{swift}'
  end

  s.subspec 'ProepertyWrapper' do |sub|
    sub.source_files = 'LarkFoundation/PropertyWrapper/*.{swift}'
  end

  s.subspec 'Encryption' do |sub|
    sub.source_files = 'LarkFoundation/Encryption/*.{h,m}'
  end

  s.subspec 'URL' do |sub|
    sub.source_files = 'LarkFoundation/URL/*.swift'
  end

  s.subspec 'JumpApplication' do |sub|
    sub.source_files = 'LarkFoundation/JumpApplication/*.{h,m}'
  end

  s.subspec 'Date' do |sub|
    sub.source_files = 'LarkFoundation/Date/*.{swift}'
  end

  s.subspec 'Debug' do |sub|
    sub.source_files = 'LarkFoundation/String+Debug/*.swift'
  end

  s.subspec 'Associated' do |sub|
    sub.source_files = 'LarkFoundation/Associated/*.swift'
  end

  s.dependency 'LarkCompatible'
  s.dependency 'LKLoadable'
end
