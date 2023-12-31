#
# Be sure to run `pod lib lint LarkCompatible.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LarkCompatible"
  s.version = "0.22.0"
  s.summary          = "LarkCompatible EE iOS SDK组件"
  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/LarkCompatible'
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "kongkaikai@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.5"
  s.source_files = 'src/**/*.{swift}'
end
