#
# Be sure to run `pod lib lint LarkActionSheet.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LarkActionSheet"
  s.version = '5.31.0.5463996'
  s.summary          = "LarkActionSheet EE iOS SDK组件"
  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/UI/LarkActionSheet'
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.dependency 'RxSwift'
  s.dependency 'SnapKit'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkTraitCollection'
  s.dependency 'LarkInteraction'
  s.dependency 'UniverseDesignColor'

  s.resource_bundles = {
    'LarkActionSheet' => ['resources/*'],
    'LarkActionSheetAuto' => ['auto_resources/*']
  }
end
