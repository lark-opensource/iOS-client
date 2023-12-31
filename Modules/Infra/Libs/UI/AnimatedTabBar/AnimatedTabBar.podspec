#
# Be sure to run `pod lib lint AnimatedTabBar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "AnimatedTabBar"
  s.version = '5.30.0.5410491'
  s.summary          = "AnimatedTabBar EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.aaa
                       DESC

  s.homepage         = 'https://ee.byted.org/madeira/browse/ee/ios-infra/tree/master/Libs/UI/AnimatedTabBar'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"

  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency "SnapKit"
  s.dependency 'Homeric'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'LarkBadge'
  s.dependency 'LarkTraitCollection'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkExtensions'
  s.dependency "LarkKeyboardKit"
  s.dependency 'LarkInteraction'
  s.dependency 'LKLoadable'
  s.dependency 'FigmaKit'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignMenu'
  s.dependency 'UniverseDesignToast'
  s.dependency 'LarkTab'
  s.dependency 'ByteWebImage'
  s.dependency 'LKWindowManager'
  s.dependency 'LarkStorage/KeyValue'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkQuickLaunchInterface'
  s.dependency 'LarkBoxSetting'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkSetting'
  s.dependency 'LarkDocsIcon'

  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.resource_bundles = {
      'AnimatedTabBar' => ['resources/*'],
      'AnimatedTabBarAuto' => ['auto_resources/*'],
  }
end
