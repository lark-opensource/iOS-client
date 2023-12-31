Pod::Spec.new do |s|
  s.name          = 'LarkForward'
  s.version = '5.31.0.5465501'
  s.author        = { 'Zhao Chen' => 'zhaochen.09@bytedance.com' }
  s.license       = 'MIT'
  s.homepage      = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkForward'
  s.summary       = '转发'
  s.source        = { :git => 'ssh://git.byted.org:29418/ee/lark/ios/LarkBusinessModule', :tag => s.version.to_s }
  s.source_files  = 'src/**/*.swift'
  s.resource_bundles = {
    'LarkForward' => ['resources/*'],
    'LarkForwardAuto' => ['auto_resources/*']
  }
  s.preserve_paths = 'configurations/**/*'
  s.platform      = :ios
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"

  s.dependency 'LarkCore'
  s.dependency 'SnapKit'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkUIKit'
  s.dependency 'RxSwift'
  s.dependency 'LarkModel'
  s.dependency 'LarkFeatureGating'
  s.dependency 'LarkContainer'
  s.dependency 'LarkExtensionCommon'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkAudio'
  s.dependency 'LarkKeyboardKit'
  s.dependency 'LarkBaseKeyboard'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkSnsShare'
  s.dependency 'LarkSendMessage'
  
  s.dependency 'LarkSegmentedView'
  s.dependency 'LarkSearchCore'
  s.dependency 'LarkListItem'
  s.dependency 'LarkStorage'
  s.dependency 'LarkFocusInterface'
  
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkEMM'

  s.dependency 'LarkKASDKAssemble'
  s.dependency 'Homeric'
  # 敏感API管控SDK 剪贴板
  s.dependency 'LarkSensitivityControl/API/Pasteboard'
end
