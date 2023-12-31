#
# Be sure to run `pod lib lint Mail.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# # To learn more about  EEScaffold see http://eescaffold.ee-dns.top
#

Pod::Spec.new do |s|
  s.name             = "MailSDK"


  s.version = '5.31.0.5483980'


  s.summary          = "Mail EE iOS SDK组件"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "Mail iOS SDK"
  s.homepage = 'git@code.byted.org:ee/mail-ios-client.git'
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "tanzhiyuan" => "tanzhiyuan@bytedance.com" }
  s.source           = { :git => "ssh://git.byted.org:29418/ee/EEScaffoldd", :tag => s.version.to_s}
  s.ios.deployment_target = '10.0'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.swift_version = '4.2'
  s.public_header_files    = ['MailSDK/MailSDK.h']
  s.source_files = [
    'Classes/MailSDK.h',
    'Classes/**/*.{swift}',
    'MailFoundation/**/*.{swift,xib,h,m,mm}',
    'MailUIKit/**/*.{swift}',
    'DataManager/**/*.{swift}',
    'Foundation/**/*.{swift,h,m}',
    'Business/**/*.{swift}',
    'Services/**/*.{swift}',
    'src/**/*.{swift,h,m,mm}',
    'Mail/**/*.{swift,h,m,mm}'
  ]

  s.subspec 'Resources' do |cs|
    cs.resource_bundles = {
      # 后期资源Core分开, localized string 和 image 还有其他JS
      'MailSDK' => [
        'Resources/*.xcprivacy',
        'Resources/SupportFiles/*',
        'Resources/mail-native-template/template/*'
      ],
      'MailSDKAuto' => ['auto_resources/*']
    }
  end

  ### configs
  s.xcconfig     = {
      'ENABLE_BITCODE'  => 'NO',
      'OTHER_LDFLAGS' => '-ObjC'
  }
  s.dependency 'LarkModel'


  # platform dependencies
  s.dependency 'LarkRustClient'
  s.dependency 'LarkSplitViewController'

  s.dependency 'PocketSVG'
  s.dependency 'Alamofire'
  s.dependency 'SwiftyJSON'
  s.dependency 'SnapKit'
  s.dependency 'lottie-ios'
  s.dependency 'Kingfisher'
  s.dependency 'ReachabilitySwift'
  s.dependency 'KeychainAccess'
  s.dependency 'MBProgressHUD'
  s.dependency 'SkeletonView'
  s.dependency 'CryptoSwift'
#  s.dependency 'IESGeckoKit', '0.3.5'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LarkUIKit'
  s.dependency 'YYCache'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkFoundation'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxDataSources'
  s.dependency 'RoundedHUD'
  s.dependency 'LarkRustHTTP'
  s.dependency 'EENavigator'
  s.dependency 'LarkAppResources'
  s.dependency 'LarkTag'
  s.dependency 'RustPB'
  s.dependency 'LarkAlertController'
  s.dependency 'SSZipArchive'
  s.dependency 'EditTextView'
  s.dependency 'Heimdallr/Monitors'
  s.dependency 'Heimdallr/TTMonitor'
  s.dependency 'Heimdallr/HMDStart'
  s.dependency 'Heimdallr/HMDANR'
  s.dependency 'Heimdallr/CrashDetector'
  s.dependency 'Homeric'
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkDatePickerView'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'ByteWebImage'
  s.dependency 'LarkNavigation'
  s.dependency 'ESPullToRefresh'
  s.dependency 'LarkEditorJS'
  s.dependency 'LarkDatePickerView'
  s.dependency 'LarkCache'
  s.dependency 'LarkWebViewContainer'
  s.dependency 'LarkWebviewNativeComponent'
  s.dependency 'LarkNavigator'
  s.dependency 'YYText'
  s.dependency 'LarkSwipeCellKit'
  s.dependency 'LarkEMM'
  s.dependency 'LarkSensitivityControl/Core'
  s.dependency 'LarkSensitivityControl/API/Pasteboard'
  s.dependency 'LarkSensitivityControl/API/Album'
  # Emoji
  s.dependency 'LarkEmotionKeyboard'
  s.dependency 'LarkEmotion'
  s.dependency 'LarkMenuController'
  s.dependency 'LarkReactionDetailController'
  s.dependency 'LarkReactionView'

  # DS组件
  s.dependency 'UniverseDesignActionPanel'
  s.dependency 'UniverseDesignBadge'
  s.dependency 'UniverseDesignBreadcrumb'
  s.dependency 'UniverseDesignButton'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignCheckBox'
  s.dependency 'UniverseDesignDatePicker'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'UniverseDesignDrawer'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignFont'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignMenu'
  s.dependency 'UniverseDesignNotice'
  s.dependency 'UniverseDesignPopover'
  s.dependency 'UniverseDesignStyle'
  s.dependency 'UniverseDesignTabs'
  s.dependency 'UniverseDesignTag'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'UniverseDesignToast'
  s.dependency 'UniverseDesignLoading'
  s.dependency 'UniverseDesignProgressView'
  s.dependency 'UniverseDesignSwitch'
  s.dependency 'UniverseDesignColorPicker'
  s.dependency 'FigmaKit'
  s.dependency 'UniverseDesignInput'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'LarkIllustrationResource'
  s.dependency 'LarkStorage'
  s.dependency 'LarkClean'
  s.dependency 'LarkAIInfra'
  s.dependency 'MailNativeTemplate'
  s.dependency 'LarkBizAvatar'
  s.dependency 'LarkContainer'
  s.dependency 'DateToolsSwift'
  s.dependency 'JTAppleCalendar'
  s.dependency 'LarkTimeFormatUtils'

  s.default_subspecs = 'Resources'

  attributes_hash = s.instance_variable_get("@attributes_hash")
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  attributes_hash['lark_group'] = {
    "bot": "c1013c81a0be4d2ca53aa4f19502a603"
  }

  s.preserve_paths = ['Scripts', 'MailSDK.podspec']
  #s.script_phase = { :name => 'replaceVersionString', :script => 'sh ${PODS_TARGET_SRCROOT}/Scripts/replaceVersionString.sh', :execution_position => :before_compile}
end
