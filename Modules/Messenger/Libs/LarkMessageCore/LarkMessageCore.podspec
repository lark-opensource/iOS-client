#
# Be sure to run `pod lib lint LarkMessageCore.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "LarkMessageCore"
  s.version = '5.31.0.5470696'
  s.summary          = 'chat/thread相关的。菜单、cell、action、messageContent等。'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "TODO: Add long description of the pod here.aaa"
  s.homepage = 'https://ee.byted.org/madeira/browse/ee/lark/ios-client/tree/master/LarkMessageCore'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "EE iOS Infra" => "dongzhao.stone@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd"}
  s.ios.deployment_target = "11.0"
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.swift_version = "5.1"
  s.source_files = 'src/**/*.{swift,h,m,mm,cpp}'
  s.resource_bundles = {
      'LarkMessageCore' => ['resources/*'] ,
      'LarkMessageCoreAuto' => 'auto_resources/*'
  }

  s.dependency 'LarkLocalizations'
  s.dependency 'LarkCore'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkModel'
  s.dependency 'LarkFeatureGating'
  s.dependency 'EEFlexiable'
  s.dependency 'AsyncComponent'
  s.dependency 'LarkEmotion'
  s.dependency 'LarkMessageBase'
  s.dependency 'LarkAudio'
  s.dependency 'UIImageViewAlignedSwift'
  s.dependency 'LarkMenuController'
  s.dependency 'LarkSheetMenu'
  s.dependency 'LarkAlertController'
  s.dependency 'SelectMenu'
  s.dependency 'LarkDatePickerView'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkPerf'
  s.dependency 'TTVideoEngine'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkAttachmentUploader'
  s.dependency 'LarkMessengerInterface'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'LarkSetting'
  s.dependency 'TTVideoEditor/LarkMode'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'LarkFeatureSwitch'
  s.dependency 'LarkKeyCommandKit'
  s.dependency 'LarkKeyboardKit'
  s.dependency 'SuiteAppConfig'
  s.dependency 'LarkRichTextCore'
  s.dependency 'LarkSDKInterface'
  s.dependency 'LarkOpenFeed'
  s.dependency 'RxSwift'
  s.dependency 'LarkContainer'
  s.dependency 'LarkBizAvatar'
  s.dependency 'LarkOPInterface/OPInterfaceSwiftHeader'
  s.dependency 'LarkCanvas'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'Homeric'
  s.dependency 'LarkCache'
  s.dependency 'LarkFoundation'
  s.dependency 'LKContentFix'
  s.dependency 'LarkStorage'
  s.dependency 'LarkSecurityAudit'
  s.dependency 'LarkSecurityComplianceInterface'
  s.dependency 'LarkSuspendable'
  s.dependency 'TangramComponent'
  s.dependency 'TangramUIComponent'
  s.dependency 'TangramService'
  s.dependency 'DynamicURLComponent'
  s.dependency 'UniverseDesignNotice'
  s.dependency 'ByteWebImage'
  s.dependency 'FigmaKit'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'RustPB'
  s.dependency 'UniverseDesignCardHeader'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'LarkFocus'
  s.dependency 'LarkOpenChat'
  s.dependency 'LarkKASDKAssemble'
  s.dependency 'LarkAssetsBrowser'
  s.dependency 'UniverseDesignColor'
  s.dependency 'LarkVideoDirector'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'LarkTracing'
  s.dependency 'LarkSafety'
  s.dependency 'LKLoadable'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkVote'
  s.dependency 'LarkMedia'
  s.dependency 'UniverseDesignMenu'
  s.dependency 'LarkEMM'
  s.dependency 'LarkSendMessage'
  s.dependency 'LarkBizTag'
  s.dependency 'LarkBaseKeyboard'
  s.dependency 'LarkChatOpenKeyboard'
  s.dependency 'LarkAIInfra'
  s.dependency 'LarkPreload'
  s.dependency 'LarkChatKeyboardInterface'

  s.test_spec 'Tests' do |test_spec|
    test_spec.test_type = :unit
    test_spec.source_files = 'tests/*.{swift,h,m,mm,cpp}'
    test_spec.pod_target_xcconfig = {
      'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
    }
    test_spec.scheme = {
      :code_coverage => true
    }
  end
end
