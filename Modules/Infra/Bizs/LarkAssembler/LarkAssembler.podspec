Pod::Spec.new do |s|
  s.name             = 'LarkAssembler'
  s.version          = '0.1.0-alpha.0'
  s.summary          = 'for Lark Assembly'
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/lark/ios/LarkAssembler/tree/master/'
  s.license          = 'MIT'
  s.source           = { git: 'ssh://git.byted.org:29418/ee/lark/ios/LarkAssembler', tag: s.version.to_s }

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "name": 'yangjing.sniper@bytedance.com'
  }

  s.platform      = :ios
  s.ios.deployment_target = '11.0'
  s.static_framework = true
  s.swift_version = '5.0'

  s.subspec 'default' do |sp|
    sp.source_files = 'src/Assembly/*.swift'
    sp.dependency 'Swinject'
    sp.dependency 'LKLoadable'
  end

  s.subspec 'SwinjectBuilder' do |sp|
    sp.source_files = 'src/Assembly/SwinjectBuilder/*.swift'
    sp.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => ' -D SwinjectBuilder' }
    sp.dependency 'Swinject'
  end

  s.subspec 'BootManagerBuilder' do |sp|
    sp.source_files = 'src/Assembly/BootManagerBuilder/*.swift'
    sp.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => ' -D BootManagerBuilder' }
    sp.dependency 'BootManager'
  end

  s.subspec 'EENavigatorBuilder' do |sp|
    sp.source_files = 'src/Assembly/EENavigatorBuilder/*.swift'
    sp.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => ' -D EENavigatorBuilder' }
    sp.dependency 'EENavigator'
  end

  s.subspec 'LarkRustClientInBuilder' do |sp|
    sp.source_files = 'src/Assembly/LarkRustClientInBuilder/*.swift'
    sp.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => ' -D LarkRustClientInBuilder' }
    sp.dependency 'LarkRustClient'
  end

  s.subspec 'LarkAccountInterfaceBuilder' do |sp|
    sp.source_files = 'src/Assembly/LarkAccountInterfaceBuilder/*.swift'
    sp.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => ' -D LarkAccountInterfaceBuilder' }
    sp.dependency 'LarkAccountInterface'
    sp.dependency 'LarkContainer'
  end

  s.subspec 'LarkTabBuilder' do |sp|
    sp.source_files = 'src/Assembly/LarkTabBuilder/*.swift'
    sp.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => ' -D LarkTabBuilder' }
    sp.dependency 'LarkTab'
  end

  s.subspec 'AppContainerBuilder' do |sp|
    sp.source_files = 'src/Assembly/AppContainerBuilder/*.swift'
    sp.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => ' -D AppContainerBuilder' }
    sp.dependency 'AppContainer'
  end

  s.subspec 'LarkDebugExtensionPointBuilder' do |sp|
    sp.source_files = 'src/Assembly/LarkDebugExtensionPointBuilder/*.swift'
    sp.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => ' -D LarkDebugExtensionPointBuilder' }
    sp.dependency 'LarkDebugExtensionPoint'
  end

  s.default_subspecs = 'default', 'SwinjectBuilder', 'BootManagerBuilder', 'EENavigatorBuilder', 'LarkRustClientInBuilder', 'LarkAccountInterfaceBuilder', 'LarkTabBuilder', 'AppContainerBuilder', 'LarkDebugExtensionPointBuilder'
end
