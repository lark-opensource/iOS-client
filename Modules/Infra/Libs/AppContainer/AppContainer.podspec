#
# Be sure to run `pod lib lint AppContainer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "AppContainer"
  s.version = '5.31.0.5466715'
  s.summary          = "AppContainer EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.aaa
                       DESC

  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/AppContainer'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "liuwanlin" => "liuwanlin@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.dependency  'LKCommonsLogging'
  s.dependency  'Swinject'
  s.dependency  'LarkContainer'
  s.dependency  'ThreadSafeDataStructure'
  s.dependency  'BootManager'
  s.dependency  'LKLoadable'
  s.dependency  'LarkSceneManager'
  s.dependency  'UniverseDesignTheme'
  s.dependency  'Heimdallr'
  s.dependency  'LarkFoundation'
  s.dependency  'LarkExtensions'
end
