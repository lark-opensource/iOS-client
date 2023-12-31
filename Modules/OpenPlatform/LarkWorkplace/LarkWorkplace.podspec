 Pod::Spec.new do |s|
  s.name         = "LarkWorkplace"
  s.version = '5.31.0.5461589'
  s.summary      = '工作台'
  s.description  = 'LarkWorkplace for lark'
  s.homepage     = 'https://code.byted.org/ee/microapp-iOS-sdk/tree/develop/LarkWorkplace'
  s.license      = 'MIT'
  s.author       = { "zhanghaitao" => "zhanghaitao.ysl@bytedance.com" }
  s.source       = { :git => "ssh://git.byted.org:29418/ee/lark/ios-LarkWorkplace", :tag => "#{s.version}" }
  s.source_files  =  'src/**/*.swift'
  s.resource_bundles = {
      'LarkWorkplace' => ['resources/*'],
      'LarkWorkplaceAuto' => ['auto_resources/*'],
  }
  s.preserve_paths = 'configurations/**/*'
  s.exclude_files = "Classes/Exclude"
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.4"

  # Workplace Base Service
  s.dependency 'LarkWorkplaceModel'
  s.dependency 'LarkOpenWorkplace'

  # Third
  s.dependency 'Alamofire'
  s.dependency 'Heimdallr'
  s.dependency 'lottie-ios'
  s.dependency 'RxCocoa'
  s.dependency 'RxRelay'
  s.dependency 'RxSwift'
  s.dependency 'SnapKit'
  s.dependency 'SwiftyJSON'                       # deprecated
  s.dependency 'Swinject'
  s.dependency 'YYCache'

  # Universe Design
  s.dependency 'UniverseDesignBadge'
  s.dependency 'UniverseDesignButton'
  s.dependency 'UniverseDesignColor'
  s.dependency 'UniverseDesignDialog'
  s.dependency 'UniverseDesignEmpty'
  s.dependency 'UniverseDesignFont'
  s.dependency 'UniverseDesignIcon'
  s.dependency 'UniverseDesignLoading'
  s.dependency 'UniverseDesignMenu'
  s.dependency 'UniverseDesignNotice'
  s.dependency 'UniverseDesignShadow'
  s.dependency 'UniverseDesignSwitch'
  s.dependency 'UniverseDesignTabs'
  s.dependency 'UniverseDesignTag'
  s.dependency 'UniverseDesignTheme'
  s.dependency 'UniverseDesignToast'

  # Lark Foundation
  s.dependency 'AppContainer'
  s.dependency 'BDWebImage'                       # deprecated: use ByteWebImage
  s.dependency 'BootManager'
  s.dependency 'ByteWebImage'
  s.dependency 'FigmaKit'
  s.dependency 'LarkAssembler'
  s.dependency 'LarkContainer'
  s.dependency 'LarkExtensions'
  s.dependency 'LarkFoundation'
  s.dependency 'LarkLocalizations'
  s.dependency 'LarkNavigator'
  s.dependency 'LarkReleaseConfig'
  s.dependency 'LarkRustClient'
  s.dependency 'LarkSetting'
  s.dependency 'LKCommonsLogging'
  s.dependency 'LKCommonsTracker'
  s.dependency 'RunloopTools'
  s.dependency 'ThreadSafeDataStructure'

  # Lark Base Service
  s.dependency 'EENavigator'
  s.dependency 'LarkAccountInterface'
  s.dependency 'LarkFeatureGating'                # deprecated: use LarkSetting
  s.dependency 'LarkGuide'
  s.dependency 'LarkNavigation'
  s.dependency 'LarkRustHTTP'
  s.dependency 'RustPB'

  # Lark UI Base
  s.dependency 'AnimatedTabBar'
  s.dependency 'LarkAlertController'
  s.dependency 'LarkBadge'                        # deprecated: use UniverseDesignBadge
  s.dependency 'LarkInteraction'
  s.dependency 'LarkKeyCommandKit'
  s.dependency 'LarkSceneManager'
  s.dependency 'LarkTab'
  s.dependency 'LarkUIKit'
  s.dependency 'LarkWebViewContainer'
  s.dependency 'RichLabel'
  s.dependency 'RoundedHUD'                       # deprecated: use UniverseDesignToast
  s.dependency 'WebBrowser'

  # Ecosystem Base
  s.dependency 'Blockit'
  s.dependency 'ECOInfra'
  s.dependency 'ECOProbe'
  s.dependency 'ECOProbeMeta'
  s.dependency 'EcosystemWeb'                     # deprecated
  s.dependency 'EEMicroAppSDK'                    # deprecated
  s.dependency 'LarkAppLinkSDK'
  s.dependency 'LarkOPInterface'
  s.dependency 'OPBlockInterface'
  s.dependency 'OPFoundation'
  s.dependency 'OPSDK'                            # deprecated
  s.dependency 'OPWebApp'                         # deprecated
  s.dependency 'TTMicroApp/Card'                  # deprecated
  s.dependency 'TTVideoEngine'
  s.dependency 'LarkEMM'
end
