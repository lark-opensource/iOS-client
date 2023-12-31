#
# Be sure to run `pod lib lint ByteWebImage.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ByteWebImage'
  s.version = '5.31.0.5470696'
  s.summary          = 'A framework for image processing.'

  s.description      = <<-DESC
  Supports image download, cache, codec and other functions.
  DESC

  s.homepage         = 'https://code.byted.org/iOS_Library/ByteWebImage'
  s.license          = { :type => 'MIT', :file => './../LICENSE' }
  s.author           = { 'xiongmin' => 'xiongmin.super@bytedance.com' }
  s.source           = { :git => 'https://code.byted.org/iOS_Library/ByteWebImage.git', :tag => s.version.to_s }

  s.static_framework = true
  s.swift_version = '5.0'
  s.ios.deployment_target = '11.0'

  s.default_subspecs = 'Core/Business', 'Monitor'
  s.private_header_files = 'Sources/Core/*.h'

  s.subspec 'Core' do |core|
    core.subspec 'Base' do |base|
      base.source_files = 'Sources/Core/Base/**/*.swift'
    end

    core.subspec 'Business' do |bizs|
      bizs.source_files = 'Sources/Core/Business/**/*.swift'
      bizs.frameworks = 'Foundation', 'UIKit'

      bizs.dependency 'ByteWebImage/Core/Manager'
      bizs.dependency 'ByteWebImage/Core/Loader'
      bizs.dependency 'ByteWebImage/Core/Cache'
      bizs.dependency 'ByteWebImage/Monitor'
      bizs.dependency 'ByteWebImage/Configuration'
    end

    core.subspec 'Manager' do |manager|
      manager.source_files = 'Sources/Core/Manager/**/*.swift'
      manager.frameworks = 'Foundation', 'UIKit'

      manager.dependency 'ThreadSafeDataStructure'
      manager.dependency 'EEAtomic'
      manager.dependency 'ByteWebImage/Core/Base'
      manager.dependency 'ByteWebImage/Monitor'
    end

    core.subspec 'Loader' do |loader|
      loader.source_files = 'Sources/Core/Loader/**/*.swift'
      loader.frameworks = 'Foundation', 'UIKit'
    end

    core.subspec 'Cache' do |cache|
      cache.source_files = 'Sources/Core/Cache/**/*.swift'
      cache.frameworks = 'Foundation', 'UIKit'

      cache.dependency 'YYCache'
      cache.dependency 'EEAtomic'
      cache.dependency 'ThreadSafeDataStructure'
      cache.dependency 'ByteWebImage/Core/Utils'
      cache.dependency 'ByteWebImage/Log'
    end

    core.subspec 'Codable' do |codable|
      codable.source_files = 'Sources/Core/Codable/**/*.{swift,h,c,m}'
      codable.frameworks = 'Foundation', 'UIKit', 'Accelerate', 'CoreServices'

      codable.dependency 'libwebp'
      codable.dependency 'ThreadSafeDataStructure'
      codable.dependency 'ByteWebImage/Core/Base'
      codable.dependency 'ByteWebImage/Core/Utils'
      codable.dependency 'ByteWebImage/Configuration'
    end

    core.subspec 'HEIC' do |heic|
      heic.source_files = 'Sources/Core/HEIC/**/*.{swift,h,c,m}'

      heic.dependency 'libttheif_ios'
      heic.dependency 'ByteWebImage/Core/Codable'
    end

    core.subspec 'Processor' do |processor|
      processor.source_files = 'Sources/Core/Processor/**/*.swift'
      processor.frameworks = 'Foundation', 'UIKit', 'Accelerate'

      processor.dependency 'ByteWebImage/Core/Base'
    end

    core.subspec 'Utils' do |utils|
      utils.source_files = 'Sources/Core/Utils/**/*.swift'

      utils.dependency 'ByteWebImage/Core/Base'
    end
  end

  s.subspec 'Monitor' do |monitor|
    monitor.source_files = 'Sources/Monitor/**/*.swift'
    monitor.frameworks = 'Foundation'
  end

  s.subspec 'Log' do |log|
    log.source_files = 'Sources/Log/**/*.swift'
    log.frameworks = 'Foundation'

    log.dependency 'ByteWebImage/Core/Base'
  end

  s.subspec 'Configuration' do |config|
    config.source_files = 'Sources/Configuration/**/*.swift'
  end

  #----------   App    ----------#

  s.subspec 'Lark' do |lark|
    lark.source_files = 'Sources/Lark/**/*.swift'
    lark.exclude_files = 'Sources/Lark/Debug/**'
    lark.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'ByteWebImage_Include_Lark' }
    lark.dependency 'AppReciableSDK'
    lark.dependency 'CookieManager'
    lark.dependency 'EEImageMagick'
    lark.dependency 'LarkAccountInterface'
    lark.dependency 'LarkCache'
    lark.dependency 'LarkEnv'
    lark.dependency 'LarkFoundation'
    lark.dependency 'LarkRustClient'
    lark.dependency 'LarkSetting'
    lark.dependency 'LKCommonsLogging'
    lark.dependency 'LKCommonsTracker'
    lark.dependency 'ReachabilitySwift'
    lark.dependency 'RustPB'
    lark.dependency 'RustSDK'
    lark.dependency 'ServerPB'
    lark.dependency 'ByteWebImage/Core'
    lark.dependency 'LarkPreload'
    lark.dependency 'LarkSensitivityControl/API/Album'
  end

  s.subspec 'LarkDebug' do |larkDebug|
    larkDebug.source_files = 'Sources/Lark/Debug/**/*.swift'
    larkDebug.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'ByteWebImage_Include_Lark_Debug' }
    larkDebug.dependency 'LarkDebugExtensionPoint'
    larkDebug.dependency 'ByteWebImage/Lark'
  end

  #----------   DocC   ----------#

  s.subspec 'DocC' do |docc|
    docc.source_files = 'DocC/**/*'
  end

  #----------   Test   ----------#

  s.subspec 'TestResources' do |res|
    res.resources = 'Tests/Resources/**/*'
  end

  s.test_spec 'Tests' do |test|
    test.source_files = 'Tests/**/*.swift'
    test.frameworks = 'UIKit', 'Foundation', 'XCTest'
    test.requires_app_host = true

    test.dependency 'ByteWebImage/Core'
    test.dependency 'ByteWebImage/Lark'
    test.dependency 'ByteWebImage/TestResources'
  end
end
