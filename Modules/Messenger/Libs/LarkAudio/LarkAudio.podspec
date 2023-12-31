#
# Be sure to run `pod lib lint LarkAudio.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "LarkAudio"
  s.version = '5.31.0.5477343'
  s.summary          = '音频录制、播放、文件管理、界面'

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/Bizs/LarkAudio'
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.frameworks = 'UIKit', 'AVFoundation', 'AudioToolbox'
  s.dependency 'LarkUIKit'
  s.dependency 'SnapKit'
  s.dependency 'RichLabel'
  s.dependency 'LarkLocalizations'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkContainer'
  s.dependency 'Swinject'
  s.dependency 'LarkModel'
  s.dependency 'EditTextView'
  s.dependency 'UniverseDesignToast'
  s.dependency 'LarkSendMessage'
  s.dependency 'LarkCore'
  s.dependency 'LarkAudioKit'
  s.dependency 'LarkAudioView'
  s.dependency 'LarkAlertController'
  s.dependency 'RunloopTools'
  s.dependency 'AppContainer'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkMedia'
  s.dependency 'LarkSensitivityControl/API/DeviceInfo'
  s.dependency 'LarkBaseKeyboard/VociePanel'
  s.dependency 'LarkChatOpenKeyboard'

  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.resource_bundles = {
      'LarkAudio' => ['resources/*'] ,
      'LarkAudioAuto' => 'auto_resources/*'
  }

end
