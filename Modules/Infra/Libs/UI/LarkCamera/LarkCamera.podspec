#
# Be sure to run `pod lib lint LarkCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LarkCamera"
  s.version = '5.30.0.5410491'
  s.summary          = "LarkCamera EE iOS SDK组件"
  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/UI/LarkCamera'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}', 'src/**/*.swift'
  s.resource_bundles = {
      'LarkCamera' => ['resources/*'],
      'LarkCameraAuto' => ['auto_resources/*']
  }

  s.framework = 'AVFoundation'
  s.dependency 'LarkLocalizations'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'LarkStorage/Sandbox'
  s.dependency 'LarkSensitivityControl/API/DeviceInfo'
  s.dependency 'LarkSensitivityControl/API/Camera'
  s.dependency 'LarkSensitivityControl/API/AudioRecord'
end
