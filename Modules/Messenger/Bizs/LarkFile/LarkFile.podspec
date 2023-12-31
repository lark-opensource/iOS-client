Pod::Spec.new do |s|
  s.name          = 'LarkFile'

  s.version = '5.31.0.5424672'
  s.author        = { 'Su Peng' => 'supeng.charlie@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkFile'
  s.summary       = '沙盒附件相关。附件预览、下载、发送等。'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkBusinessModule', :tag => s.version.to_s }
  s.source_files  = 'src/**/*.{swift,h,m}'
  s.resource_bundles = {
    'LarkFile' => ['resources/*'],
    'LarkFileAuto' => ['auto_resources/*']
  }
  s.preserve_paths = 'configurations/**/*'
  s.platform      = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"


  s.dependency 'SnapKit'
  s.dependency 'RxSwift'
  s.dependency 'LarkCore'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkModel'
  s.dependency 'LarkContainer'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'LarkFeatureSwitch'
  s.dependency 'LarkKeyCommandKit'
  s.dependency 'SuiteAppConfig'
  s.dependency 'LarkAccountInterface'
  s.dependency 'RxRelay'
  s.dependency 'LarkSDKInterface'
  s.dependency 'LarkCache'
  s.dependency 'WebBrowser'
  s.dependency 'LarkOPInterface'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkKAFeatureSwitch'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'OPFoundation'
  s.dependency 'KAFileInterface'
  s.dependency 'LarkKASDKAssemble'
  s.dependency 'LarkAssembler'
  s.dependency 'BootManager'
  s.dependency 'UniverseDesignLoading'
  s.dependency 'LarkMedia'
  s.dependency 'LarkEMM'
  s.dependency 'LarkSensitivityControl'
end
