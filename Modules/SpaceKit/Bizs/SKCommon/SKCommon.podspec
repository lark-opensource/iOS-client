# frozen_string_literal: true

#
# Be sure to run `pod lib lint SKCommon.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# To learn more about EEScaffold see http://eescaffold.web.bytedance.net
# To learn more about podspec.patch see http://eescaffold.web.bytedance.net/docs/en/podspec/patch

Pod::Spec.new do |s|
  # 修改此文件前请先浏览 *Podspec规范* https://bytedance.feishu.cn/space/doc/doccnZwORNUpwphkrhiTgv#
  s.name = 'SKCommon'
  s.version = '5.31.0.5484102'
  s.summary = 'SpaceKit 业务公共代码'
  s.description = '包含路由、网络、埋点、资源包热更以及各个模块的胶水层和基础业务，后面会拆成更细粒度的模块'
  s.homepage = 'https://code.byted.org/ee/spacekit-ios/tree/develop/Bizs/SKCommon'

  # 界面相关的Pod必填。设置为展示该界面功能的图片地址
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  # 责任人，必填。必要时要及时更新该信息
  s.authors = {
    "lijuyou": 'lijuyou@bytedance.com'
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.3'

  s.preserve_paths = ['Scripts', 'SKCommon.podspec']
  s.script_phases = [
    {
      :name => 'Check Duplicate UserDefaultKey',
      :script => '"${PODS_TARGET_SRCROOT}/Scripts/checkSameUserDefaultKey.sh"',
      :execution_position => :before_compile,
      :show_env_vars_in_log => '0'
    }
  ]


  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.resource_bundles = {
  #     'SKCommon' => ['Resources/*'] ,
  #     'SKCommonAuto' => ['auto_resources/*']
  # }


  # 以下2个字段不要修改。EEScaffold会自动修改source字段为生成的zip包地址。
  s.license          = 'MIT'
  s.source           = { git: 'generated_by_eesc.zip', tag: s.version.to_s }

  # s.frameworks = 'UIKit', 'MapKit'

  # s.dependency 'AFNetworking', '~> 2.3'
 # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SKFoundation'
  s.dependency 'SKUIKit'
  s.dependency 'SKResource'
  s.dependency 'SKInfra'
  s.dependency 'QRCode'
  s.dependency 'LarkDocsIcon'
  s.dependency 'LarkSecurityAudit'
  s.dependency 'LarkSecurityComplianceInterface'
  s.dependency 'LarkSecurityCompliance'
  s.dependency 'UniverseDesignMenu'

 
  s.dependency 'HandyJSON'
  s.dependency 'SwiftProtobuf'
  s.dependency 'LarkRustClient'

  s.dependency 'Alamofire'
  s.dependency 'ByteWebImage'
  s.dependency 'SwiftyJSON'
  s.dependency 'SnapKit'
  s.dependency 'lottie-ios'
  s.dependency 'Kingfisher'
  s.dependency 'ReachabilitySwift'
  s.dependency 'KeychainAccess'
  s.dependency 'SkeletonView'
  s.dependency 'SQLite.swift'
  s.dependency 'CryptoSwift'
  s.dependency 'Swinject'
  s.dependency 'SQLiteMigrationManager.swift'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkSuspendable'
  s.dependency 'YYCache'
  s.dependency 'LarkLocalizations'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'LarkRustHTTP'
  s.dependency 'EENavigator'
  s.dependency 'JTAppleCalendar'
  s.dependency 'LarkAudioKit'
  s.dependency 'SpaceInterface'
  s.dependency 'TTVideoEngine'
  s.dependency 'TTPlayerSDK'
  s.dependency 'MDLMediaDataLoader'
  s.dependency 'LarkReactionView'
  s.dependency 'LarkEmotion'
  s.dependency 'LarkMenuController'
  s.dependency 'LarkReactionDetailController'
  s.dependency 'mobilecv2'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkAlertController'
  s.dependency 'SSZipArchive'
  s.dependency 'LibArchiveKit'
  s.dependency 'OfflineResourceManager'
  s.dependency 'ThreadSafeDataStructure'
  s.dependency 'LarkSnsShare'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkMonitor'
  s.dependency 'LarkAppConfig'
  s.dependency 'LarkAppResources'
  s.dependency 'SuiteAppConfig'
  s.dependency 'LarkMedia'
  s.dependency 'ESPullToRefresh'
  s.dependency 'LarkSplitViewController'
  s.dependency 'RoundedHUD'
  s.dependency 'LarkCache'
  s.dependency 'LarkAddressBookSelector'
#  s.dependency 'BDABTestSDK'
  s.dependency 'LarkSceneManager'
  s.dependency 'LarkEmotionKeyboard'
  s.dependency 'UniverseDesignActionPanel'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignToast'
  s.dependency 'UniverseDesignCheckBox'
  s.dependency 'UniverseDesignFont'
  s.dependency 'UniverseDesignButton'
  s.dependency 'UniverseDesignLoading'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'UniverseDesignTabs'
  s.dependency 'UniverseDesignSwitch'
  s.dependency 'UniverseDesignDatePicker'
  s.dependency 'LarkTimeFormatUtils'
  s.dependency 'FigmaKit'
  s.dependency 'UGBanner'
  s.dependency 'UGReachSDK'
  s.dependency 'RxDataSources'
  s.dependency 'Differentiator'
  s.dependency 'LarkSetting'
  s.dependency 'RunloopTools'
  s.dependency 'WebBrowser'
  s.dependency 'LarkGuide'
  s.dependency 'MMKV'
  s.dependency 'LarkMagic'
  s.dependency 'LarkSensitivityControl/API/Album'
  s.dependency 'LarkSensitivityControl/Core'
  s.dependency 'LarkSensitivityControl/API/DeviceInfo'

  s.dependency 'LarkKAFeatureSwitch'
  
  s.dependency 'LarkClean'



  # React-Core third party
  s.dependency 'Folly', '2018.10.22.00'
  s.dependency 'glog', '0.3.5'
  s.dependency 'DoubleConversion', '1.1.6'
  
  
  s.dependency 'LarkAssetsBrowser'
  s.dependency 'ServerPB'
  s.dependency 'LarkDynamicResource'

  # Open Platform
  s.dependency 'LarkOpenPluginManager'
  s.dependency 'LarkOpenAPIModel'
  
  # Lynx
  s.dependency 'BDXServiceCenter'
  s.dependency 'BDXResourceLoader'
  s.dependency 'BDXBridgeKit'
  s.dependency 'BDXLynxKit'
  s.dependency 'BDXMonitor'
  s.dependency 'Lynx'

  # preload
  s.dependency 'LarkPreload'
  
  s.dependency 'ECOInfra'
  s.dependency 'LarkContainer'
  s.dependency 'LarkWebViewContainer'

  s.dependency 'LarkAIInfra'
  s.dependency 'CTADialog/Core'

  s.subspec 'Core' do |ss|
    ss.source_files = 'src/**/*.{swift,h,m,mm,cpp,xib}'
  end
  

  ### configs
  s.xcconfig = {
      'ENABLE_BITCODE' => 'NO',
      'OTHER_LDFLAGS' => '-ObjC -weak_framework CryptoKit'
  }

  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_HAS_CODEC=1'
  }

  attributes_hash = s.instance_variable_get('@attributes_hash')
  # setup custom bot 参考教程：https://docs.bytedance.net/doc/fuHCWYbPdHZTGODh1DbiIa#jjJE6r
  # 使用版本机器人，请关闭注释，然后填写你的bot的token到下面
  # attributes_hash['lark_group'] = {
  #  "bot": "TOKEN"
  # }
  attributes_hash['extra'] = {
    # 设置为该Pod所在的Repo的Git地址
    "git_url": 'git@code.byted.org:ee/spacekit-ios.git'
  }

    # 单元测试
  s.test_spec 'Tests' do |test_spec|
    test_spec.test_type = :unit
    test_spec.source_files = 'tests/**/*.{swift,h,m,mm,cpp}'
    test_spec.resources = 'tests/Resources/*'
    test_spec.xcconfig = {
        'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym'
    }
    test_spec.scheme = {
        :code_coverage => true,
        :environment_variables => {'UNIT_TEST' => '1'},
        :launch_arguments => []
    }
    test_spec.dependency 'OHHTTPStubs/Swift'
    test_spec.dependency 'SwiftyJSON'
  end
end
