#
# Be sure to run `pod lib lint EEFlexiable.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "EEFlexiable"
  s.version          = "0.1.9"
  s.summary          = "EEFlexiable EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/EEFlexiable/EEFlexiable'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = {
      "EE iOS Infra" => "dongzhao.stone@bytedance.com",
      "qihongye"     => "qihongye@bytedance.com"
  }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = '11.0'
  s.libraries = 'c++.1'
  s.swift_version = '5.0'
  s.static_framework = true
  s.ios.deployment_target = '11.0'
  s.source_files = 'src/*.{swift,h,m}'
  s.public_header_files = 'src/{FlexNode,FlexStyle,types,BridgeSwift}.h'

  s.dependency 'Yoga'

end
