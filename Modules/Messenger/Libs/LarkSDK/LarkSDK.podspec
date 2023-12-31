Pod::Spec.new do |s|
  s.name = 'LarkSDK'
  s.version = '5.32.0.5485092'
  s.author = { "liuwanlin" => "liuwanlin@bytedance.com" }
  s.license = 'MIT'
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkSDK'
  s.summary = 'Lark SDK Module'
  s.source = {:git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkSDK', :tag => s.version.to_s}

  s.platform = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkModel'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkRustClient'
  s.dependency 'Swinject'
  s.dependency 'LarkContainer'
  s.dependency 'NotificationUserInfo'
  s.dependency 'EENotification'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkEmotion'
  s.dependency 'LarkCustomerService'
  s.dependency 'ByteWebImage'
  s.dependency 'LarkSendMessage'
  s.dependency 'LarkSDKInterface'
  s.dependency 'LarkAccountInterface'
  s.dependency 'Homeric'
  s.dependency 'LKMetric'
  s.dependency 'LarkDebug'
  s.dependency 'LarkDebugExtensionPoint'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'LarkFeatureSwitch'
  s.dependency 'LarkAppConfig'
  s.dependency 'RustPB'
  s.dependency 'RustSDK'
  s.dependency 'LarkCache'
  s.dependency 'LarkFileKit'
  s.dependency 'LarkSetting'
  s.dependency 'ServerPB'
  s.dependency 'LarkCore'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkEmotionKeyboard'
  s.dependency 'TangramService'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkSensitivityControl/API/DeviceInfo'
  s.dependency 'LarkSecurityComplianceInterface'

  s.source_files = 'src/**/*.{swift,c}'

  s.test_spec 'Tests' do |test_spec|
    test_spec.test_type = :unit
    test_spec.source_files = 'tests/*.{swift,h,m,mm,cpp}'
    test_spec.pod_target_xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
    }
    test_spec.scheme = {
      :code_coverage => true
    }
  end
end
