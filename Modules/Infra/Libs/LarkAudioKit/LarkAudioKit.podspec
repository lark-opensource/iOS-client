#
# Be sure to run `pod lib lint LarkAudioKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "LarkAudioKit"
  s.version = '5.28.0.5366422'
  s.summary          = "LarkAudioKit EE iOS SDK组件"

  s.description      = "基础的音频播放、录音、格式转化能力"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/LarkAudioKit'
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "lichen.arthur@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.public_header_files = 'src/**/*.h'
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  # s.resource_bundles = {
  #     'LarkAudioKit' => ['resources/*'] ,
  #     'LarkAudioKitAuto' => 'auto_resources/*'
  # }
  s.frameworks = 'UIKit', 'AVFoundation', 'AudioToolbox'
  s.dependency 'oc-opus-codec'
  s.dependency 'RxSwift'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'LarkMedia'
  s.dependency 'LarkSensitivityControl/API/DeviceInfo'
  s.dependency 'LarkSensitivityControl/API/AudioRecord'
end
