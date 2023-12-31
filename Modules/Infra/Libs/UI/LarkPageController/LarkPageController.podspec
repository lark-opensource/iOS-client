#
# Be sure to run `pod lib lint LarkPageController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "LarkPageController"
  s.version = '5.31.0.5463996'
  s.summary          = "LarkPageController EE iOS SDK组件"
  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/UI/LarkPageController'
  s.license          = 'MIT'
  s.author           = { "kongkaikai@bytedance.com" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  attributes_hash = s.instance_variable_get("@attributes_hash")
end
