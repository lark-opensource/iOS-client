#
# Be sure to run `pod lib lint PresentViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "PresentContainerController"
  s.version = '5.31.0.5463996'
  s.summary          = "PresentContainerController EE iOS SDK组件"

  s.description      = "支持从页面各个方向弹出页面的组件"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/UI/PresentContainerController'
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'

  s.dependency 'SnapKit'

  attributes_hash = s.instance_variable_get("@attributes_hash")
end
