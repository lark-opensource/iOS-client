#!/usr/bin/env ruby
module LarkBinary
  class List
    def self.binary_list
      %W[
        BDUGUnionSDK
        IESGeckoKit
        LarkModel
        boringssl
        bytenn-ios
        espresso
        libwebp
        mobilecv2
        smash
        AnimatedTabBar
        AppReciableSDK
        AppsFlyerFramework
        AudioSessionScenario
        #APIHandler
        #Action
        Alamofire
        AppContainer
        AsyncComponent
        #AudioSessionScenario
        #AvatarComponent
        #BootManager
        #ConfigCenter
        CryptoSwift
        DateToolsSwift
        #Differentiator
        #EEAtomic
        #EEFlexiable
        EEImageMagick
        EEImageService
        #EEKeyValue
        #EENavigator
        #EENotification
        #EEPodInfoDebugger
        #EETroubleKiller
        #ESPullToRefresh
        #EditTextView
        #ExtensionMessenger
        HandyJSON
        Homeric
        JTAppleCalendar
        KeychainAccess
        KingfisherWebP
        LKCommonsLogging
        LKCommonsTracker
        LKContentFix
        LKMetric
        LKTracing
        LarkActionSheet
        LarkActivityIndicatorView
        LarkAppConfig
        LarkAppLinkSDK
        LarkAppLog
        LarkAppResources
        LarkAudioKit
        LarkAudioView
        LarkAvatarComponent
        LarkBGTaskScheduler
        LarkBadge
        LarkBizAvatar
        LarkButton
        LarkCache
        LarkCamera
        LarkColor
        LarkCompatible
        LarkContainer
        LarkDebug
        LarkDebugExtensionPoint
        LarkEmotion
        LarkExtensionCommon
        LarkExtensionMessage
        LarkExtensions
        LarkFeatureSwitch
        LarkFileKit
        LarkGuideUI
        LarkInteraction
        LarkKAFeatureSwitch
        LarkKeyCommandKit
        LarkKeyboardKit
        LarkLocalizations
        LarkMailInterface
        LarkMenuController
        LarkNotificationServiceExtension
        LarkNotificationServiceExtensionLib
        LarkOPInterface
        LarkOpenTrace
        LarkOrientation
        LarkPageController
        LarkPerf
        LarkPopoverKit
        LarkPushTokenUploader
        LarkReactionView
        LarkReleaseConfig
        LarkResource
        LarkRustClient
        LarkScene
        LarkSegmentedView
        LarkSettingsBundle
        LarkShareExtension
        LarkShareToken
        LarkSnsShare
        LarkSplash
        LarkSplitViewController
        LarkSwipeCellKit
        LarkTab
        LarkTag
        LarkTimeFormatUtils
        LarkTracker
        LarkTraitCollection
        LarkUIExtension
        LarkWebViewContainer
        LarkWebviewNativeComponent
        LarkZoomable
        Logger
        MLeaksFinder
        NSObject+Rx
        NotificationUserInfo
        PresentContainerController
        ReSwift
        ReachabilitySwift
        RichLabel
        RoundedHUD
        RunloopTools
        RustPB
        RxAutomaton
        RxCocoa
        RxDataSources
        RxRelay
        RxSwift
        SQLite.swift
        SQLiteMigrationManager.swift
        SecSDK
        ServerPB
        SkeletonView
        SnapKit
        SuiteAppConfig
        SuiteCodable
        SwiftLint
        SwiftProtobuf
        SwiftyJSON
        Swinject
        ThreadSafeDataStructure
        UIImageViewAlignedSwift
        VCInfra
        ZeroTrust
      ]
    end

    def self.oc_list
      %W[
        ABRInterface
        ADFeelGood
        AFNetworking
        AFgzipRequestSerializer
        AMapFoundation
        AMapSearch
        AppAuth
        BDABTestSDK
        BDALog
        BDAlogProtocol
        BDAssert
        BDDataDecorator
        BDDataDecoratorTob
        BDJSBridgeAuthManager
        BDMonitorProtocol
        BDTrackerProtocol
        BDTuring
        BDUGAccountOnekeyLogin
        BDUGContainer
        BDUGLogger
        BDUGLoggerInterface
        BDUGMonitorInterface
        BDUGShare
        BDUGTrackerInterface
        BDUGUnionSDK
        BDWebCore
        BDWebImage
        BDXElement
        BitableBridge
        ByteDanceKit
        ByteRtcSDK
        CJPay
        # EAccountApiSDK
        EffectSDK_iOS
        FBLazyVector
        FBReactNativeSpec
        FBRetainCycleDetector
        FLAnimatedImage
        FLEX
        FMDB
        Folly
        GTMAppAuth
        GTMSessionFetcher
        Gaia
        Godzippa
        GoogleAPIClientForREST
        GoogleSignIn
        Heimdallr
        IESGeckoKit
        IESJSBridgeCore
        JSONModel
        KVOController
        LLBSDMessaging
        LarkSQLCipher
        Lynx
        MBProgressHUD
        MDLMediaDataLoader
        MMKV
        MMKVCore
        Masonry
        MemoryGraphCapture
        Objection
        RCTRequired
        RCTTypeSafety
        RangersAppLog
        React-Core
        React-CoreModules
        React-RCTImage
        React-RCTNetwork
        React-cxxreact
        React-jsi
        React-jsiexecutor
        React-jsinspector
        ReactCommon
        Reveal-SDK
        SAMKeychain
        SSZipArchive
        SocketRocket
        TTBridgeUnify
        TTMacroManager
        TTNetworkManager
        TTPlayerSDK
        TTReachability
        TTRoute
        TTTopSignature
        TTVideoEngine
        TTVideoSetting
        TYRZApiSDK
        TencentQQSDK
        VCNVCloudNetwork
        WechatSDK
        WeiboSDK
        YYCache
        Yoga
        audiosdk
        boost-for-react-native
        boringssl
        bytenn-ios
        espresso
        glog
        libPhoneNumber-iOS
        libpng
        libwebp
        lottie-ios
        mobilecv2
        oc-opus-codec
        smash
        tfccsdk
        yaml-cpp
      ]
    end

    # 必须开启模块稳定的列表
    def self.must_stability_list
      %W[
        # APIHandler
        # Action
        # Alamofire
        # AppContainer
        # AppReciableSDK
        # AppReciableSDK
        # AsyncComponent
        # AudioSessionScenario
        # AvatarComponent
        # BootManager
        # ConfigCenter
        # CryptoSwift
        # DateToolsSwift
        # Differentiator
        # DoubleConversion
        # # EEAtomic
        # EEFlexiable
        # EEImageMagick
        # # EEImageService
        # # EEKeyValue
        # # EENavigator
        # EENotification
        # # EEPodInfoDebugger
        # EETroubleKiller
        # ESPullToRefresh
        # # EditTextView
        # ExtensionMessenger
        # HandyJSON
        # Homeric
        # JTAppleCalendar
        # KeychainAccess
        # Kingfisher
        # Kingfisher
        # KingfisherWebP
        # LKCommonsLogging
        # LKCommonsTracker
        # LKContentFix
        # LKMetric
        # LKTracing
        # LarkActionSheet
        # LarkActivityIndicatorView
        # LarkAppConfig
        # LarkAppLinkSDK
        # LarkAppLog
        # LarkAppResources
        # LarkAudioKit
        # LarkAudioView
        # LarkAvatarComponent
        # LarkBGTaskScheduler
        # LarkBadge
        # LarkBizAvatar
        # LarkButton
        # LarkCache
        # LarkCamera
        # LarkColor
        # LarkCompatible
        # LarkContainer
        # LarkDebug
        # LarkDebugExtensionPoint
        # LarkEmotion
        # LarkExtensionCommon
        # LarkExtensionMessage
        # LarkExtensions
        # LarkFeatureSwitch
        # LarkFileKit
        # LarkFileSystem
        # # LarkFoundation
        # LarkGuideUI
        # LarkInteraction
        # LarkKAFeatureSwitch
        # LarkKeyCommandKit
        # LarkKeyboardKit
        # LarkLocalizations
        # LarkMailInterface
        # LarkMenuController
        # LarkModel
        # LarkNotificationServiceExtension
        # LarkNotificationServiceExtensionLib
        # LarkOPInterface
        # LarkOpenTrace
        # LarkOrientation
        # LarkPageController
        # LarkPerf
        # LarkPopoverKit
        # LarkPushTokenUploader
        # LarkReactionView
        # LarkReleaseConfig
        # LarkResource
        # LarkRustClient
        # LarkSafeMode
        # LarkSafety
        # LarkSafety
        # LarkScene
        # LarkSegmentedView
        # LarkSettingsBundle
        # LarkShareExtension
        # LarkShareToken
        # LarkSnsShare
        # LarkSplash
        # LarkSplitViewController
        # LarkSwipeCellKit
        # LarkTab
        # LarkTag
        # LarkTimeFormatUtils
        # LarkTracker
        # LarkTraitCollection
        # LarkUIExtension
        # LarkWebViewContainer
        # LarkWebviewNativeComponent
        # LarkZoomable
        # Logger
        # MLeaksFinder
        # NSObject+Rx
        # NotificationUserInfo
        # PresentContainerController
        # PushKitService
        # ReSwift
        # ReachabilitySwift
        # RichLabel
        # RoundedHUD
        # RunloopTools
        # RustPB
        # RxAutomaton
        # RxCocoa
        # RxDataSources
        # RxRelay
        # RxSwift
        # SQLite.swift
        # SQLiteMigrationManager.swift
        # SecSDK
        # ServerPB
        # SkeletonView
        # SnapKit
        # Sodium
        # SuiteAppConfig
        # SuiteCodable
        # SwiftLint
        # SwiftProtobuf
        # SwiftyJSON
        # Swinject
        # TTVideoEditor
        # ThreadSafeDataStructure
        # UIImageViewAlignedSwift
        # VCInfra
        # ZeroTrust
        # LarkAccountInterface
        # LarkCombine
        # LarkEnv
        # LarkFeatureGating
        # LarkSDKInterface
        # LarkSceneManager
        # TTAdSplashSDK
        # LarkMessageBase
        # OpenCombine
        # OpenCombineDispatch
        # OpenCombineFoundation
      ]
    end
  end
end
