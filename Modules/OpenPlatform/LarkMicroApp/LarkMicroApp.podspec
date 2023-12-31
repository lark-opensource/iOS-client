 Pod::Spec.new do |s|
  s.name         = "LarkMicroApp"
  s.version = '5.31.0.5478545'
  s.summary      = 'Micro App for Lark.'
  s.description  = "A engine support for micro app like lark moment, vote, etc."
  s.homepage     = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkMicroApp'
  s.license      = 'MIT'
  s.author       = { "yinyuan.0" => "yinyuan.0@bytedance.com" }
  s.source       = { :git => "ssh://git.byted.org:29418/ee/lark/ios-LarkMicroApp", :tag => "#{s.version}" }
  s.source_files  = 'src/**/*.swift'
  s.resource_bundles = {
      'LarkMicroApp' => ['resources/*'],
      'LarkMicroAppAuto' => ['auto_resources/*']
  }
  s.preserve_paths = 'configurations/**/*'
  s.exclude_files = "Classes/Exclude"
  s.ios.deployment_target = "11.0"
  s.dependency 'BootManager'
  s.dependency 'CryptoSwift'
  s.dependency 'EEMicroAppSDK'
  s.dependency 'EENavigator'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkAppConfig'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'LarkContainer'
  s.dependency 'LarkDebugExtensionPoint'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkFeatureSwitch'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkModel'
  s.dependency 'LarkMonitor'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkTab'
  s.dependency 'LarkOPInterface'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkUIKit'
  s.dependency 'RxCocoa'
  s.dependency 'RxSwift'
  s.dependency 'SuiteAppConfig'
  s.dependency 'Swinject'
  s.dependency 'TTMicroApp'
  s.dependency 'OPSDK'
  s.dependency 'OPGadget'
  s.dependency 'LarkSceneManager'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkAssembler'
  s.dependency 'LKLoadable'
end
