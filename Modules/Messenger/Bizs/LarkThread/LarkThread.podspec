#
# Be sure to run `pod lib lint LarkThread.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "LarkThread"
  s.version = '5.31.0.5470696'
  s.summary          = 'LarkThread EE iOS SDK组件'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkThread'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.resource_bundles = {
      'LarkThread' => ['resources/*'] ,
      'LarkThreadAuto' => 'auto_resources/*'
  }

  s.dependency 'LarkLocalizations'
  s.dependency 'Swinject'
  s.dependency 'LarkContainer'
  s.dependency 'LarkModel'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkFeatureGating'
  s.dependency 'AsyncComponent'
  s.dependency 'LarkMessageCore'
  s.dependency 'LarkMessageBase'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkAccountInterface'
  s.dependency 'SkeletonView'
  s.dependency 'LarkInteraction'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'LarkFeatureSwitch'
  s.dependency 'LarkKeyCommandKit'
  s.dependency 'SuiteAppConfig'
  s.dependency 'BootManager'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'LarkCanvas'
  s.dependency 'LarkAI'
  s.dependency 'LarkKAFeatureSwitch'
  s.dependency 'LarkSuspendable'
  s.dependency 'LarkEmotionKeyboard'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignTabs'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'LarkIllustrationResource'
  s.dependency 'LarkOpenChat'
  s.dependency 'LarkWaterMark'
  s.dependency 'LarkIMMention'
  s.dependency 'LarkEMM'
  s.dependency 'LarkBaseKeyboard'
  s.dependency 'LarkChatOpenKeyboard'
  s.dependency 'LarkQuickLaunchInterface'
  s.dependency 'LarkExtensions'
end
