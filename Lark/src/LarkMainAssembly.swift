//
//  LarkMainAssembly.swift
//  Lark
//
//  Created by KT on 2020/8/18.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import Swinject
import LarkSDKInterface
import LarkMessengerInterface
import LarkBaseService
import CCMMod
import ByteViewMod
import LarkOpenPlatformAssembly
import LarkOpenPlatform
import LarkAudio
import LarkAccountAssembly
import LarkFontAssembly
import LarkMail
import MessengerMod
import HelpDesk
import LarkDebug
import LarkQRCode
import LarkAppConfig
import LarkNavigationAssembly
import AnimatedTabBar
import LarkLiveMod
import WorkplaceMod
import LarkMicroApp
import LarkLaunchGuide
import LarkTour
import LarkAppLinkSDK
import LarkCreateTeam
import LarkGuide
import LarkSDK
import LarkTabMicroApp
import SecSDK
import LarkPushTokenUploader
import LarkLeanMode
import LarkSnsShare
import LarkSettingsBundle
import LarkPrivacyAlert
import Calendar
import BootManager
import LarkSplash
import ZeroTrust
import BlockMod
import LarkMagicAssembly
import LarkVersionAssembly
import WebBrowser
import LarkSecurityAudit
import LarkWidgetService
import LarkAppStateSDK
import LarkMine
import LarkMention
import LarkIMMention
import Moment
import LarkShareContainer
import LarkSuspendable
import MinutesMod
import SuiteAppConfig
import LarkRustClientAssembly
import UGReachSDK
import LarkDialogManager
import LarkPushCard
import LarkEmotion
import LarkEnterpriseNotice
import LarkDynamicResource
import LarkImageEditor
import TangramService
import LarkVote
import LarkLynxKit
import LarkMessageCard
#if canImport(LarkFeedback)
import LarkFeedback
#endif
import LarkMinimumMode
#if canImport(LarkCodeCoverage)
import LarkCodeCoverage
#endif
#if canImport(LarkOfflineCodeCoverage)
import LarkOfflineCodeCoverage
#endif
import EcosystemWeb
import LarkSetting
import LarkQuaterback
#if canImport(MeegoMod)
import LarkFlutterContainer
import MeegoMod
#endif
import CalendarMod
import TodoMod
import LarkWaterMark
import LarkExtensionAssembly
import LarkKASDKAssemble
import ECOInfra
import LarkCloudScheme
import LKLoadable
import LarkEmotionKeyboard
import LarkAssembler
import LarkCoreLocation
import LarkSecurityCompliance
import LarkBadgeAssembly
import URLInterceptorManagerAssembly
import LarkCacheAssembly
import LarkSceneManagerAssembly
import LarkBGTaskScheduler
import LarkContactComponent
#if canImport(LarkKAExpiredObserver)
import LarkKAExpiredObserver
#endif
#if canImport(KAEMMServiceIMP)
import KAEMMServiceIMP
#endif
import LarkVideoDirector
import LarkStorageAssembly
import LarkCleanAssembly
#if canImport(LKAppLinkExternalAssembly)
import LKAppLinkExternalAssembly
#endif
#if canImport(LKJsApiExternalAssembly)
import LKJsApiExternalAssembly
#endif
#if canImport(LKKeyValueExternalAssembly)
import LKKeyValueExternalAssembly
#endif
#if canImport(LKQRCodeExternalAssembly)
import LKQRCodeExternalAssembly
#endif
#if canImport(LKLifecycleExternalAssembly)
import LKLifecycleExternalAssembly
#endif
#if canImport(LKStatisticsExternalAssembly)
import LKStatisticsExternalAssembly
#endif
import LarkGeckoTTNet
import LarkPageIn
#if canImport(LKPassportExternalAssembly)
import LKPassportExternalAssembly
#endif
#if canImport(LKSettingExternalAssembly)
import LKSettingExternalAssembly
#endif
#if canImport(LKLoggerExternalAssembly)
import LKLoggerExternalAssembly
#endif
#if canImport(LKPassportOperationExternalAssembly)
import LKPassportOperationExternalAssembly
#endif
#if canImport(LKMessageExternalAssembly)
import LKMessageExternalAssembly
#endif
#if canImport(LarkKAEMM)
import LarkKAEMM
#endif
#if canImport(UDDebug)
import UDDebug
#endif
#if canImport(LKMenusExternalAssembly)
import LKMenusExternalAssembly
#endif
import LarkStorage
import CTADialog
import LarkBoxSettingAssembly
import LarkNotificationAssembly
import LarkPreloadDependency
import LarkDowngradeDependency
import LarkDocsIcon
import LarkAIInfra
import LarkIcon
import SKBitable
#if canImport(LarkShortcutAssembly)
import LarkShortcutAssembly
#endif

final class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        let assemblies: [Assembly]
        let assemblyInterfaces: [LarkAssemblyInterface]
        if KVPublic.Core.minimumMode.value() {
            assemblies = []
            assemblyInterfaces = minimumAssemblyInteraces
        } else {
            assemblies = allAssemblies
            assemblyInterfaces = allAssemblyInterface
        }
        _ = Assembler(assemblies: assemblies, assemblyInterfaces: assemblyInterfaces, container: BootLoader.container)
        BootLoader.assemblyLoaded = true
    }
}
//旧assembly集合，不要再添加Assembly，后面逐渐废弃该方案
fileprivate let allAssemblies: [Assembly] = {
    var list: [Assembly] = [
//        MessageQueueAssembly()
    ]
    return list
}()
//新Assembly集合，Assembly都往这里添加
fileprivate let allAssemblyInterface: [LarkAssemblyInterface] = {
    var list: [LarkAssemblyInterface] = [
        WebAssemblyV2(),
        OtherAssemblyV2(),
        EcosystemWebAssemblyV2(),
        LarkAccountAssembly(),
        SuiteAppConfigAssembly(),
        RustClientAssembly(),
        SettingAssembly(),
        ConfigAssembly(),
        LarkDebug.DebugAssembly(),
        LarkBaseServiceAssembly(),
        PrivacyAlertAssembly(),
        LaunchGuideAssembly(),
        LarkPushTokenUploaderAssembly(),
        TourAssembly(),
        DefaultLarkTourDependencyAssembly(),
        CreateTeamAssembly(),
        LarkNavigationAssembly(),
        AnimatedTabBarAssembly(),
        ECOInfraDependencyAssembly(),
        ECOCookieAssembly(),
        ECONetworkAssembly(),
        ECOProbeDependencyAssembly(),
        MessengerAssembly(),
        LeanModeAssembly(),
        LarkCalendarAssembly(),
        SpaceKitAssemble(),
        LarkByteViewAssembly(),
        LarkLiveAssembly(),
        LarkAppStateSDKAssembly(),
        LarkOpenPlatformAssembly(),
        LarkMessageCardAssembly(),
        LarkLynxAssembly(),
        BlockAssembly(),
        WorkplaceAssembly(),
        MicroAppPrepareAssembly(),
        MicroAppAssembly(),
        LarkMicroAppAssembly(),
        MailAssemble(),
        AppLinkAssembly(),
        TabMicroAppAssembly(),
        LarkTodoAssembly(),
        HelpdeskAssembly(),
        SecGuardAssembly(),
        LarkSnsShareBaseAssembly(),
        LarkSnsShareAssembly(),
        LarkFontAssembly(),
        LarkPushCardAssembly(),
        SettingsBundleAssembly(),
        SplashAssembly(),
        ZeroTrustAssembly(),
        LarkMagicAssembly(),
        LarkVersionAssembly(),
        SecurityAuditAssembly(),
        LarkGuideAssembly(),
        LarkWidgetAssembly(),
        LarkShareContainerAssembly(),
        SuspendAssembly(),
        ThemeAssembly(),
        LarkMinutesAssembly(),
        LarkDynamicResourceAssembly(),
        LarkBoxSettingAssembly(),
        ReachSDKAssembly(),
        DialogManagerAssembly(),
        EmotionAssembly(),
        EmotionKeyboardAssembly(),
        MinimumAssembly(),
        TangramAssembly(),
        LarkQuaterbackAssembly(),
        LarkMailAssembly(),
        ExtensionAssembly(),
        CloudSchemeAssembly(),
        KATabAssembly(),
        LarkCoreLocationAssembly(),
        BadgeAssembly(),
        CacheManagerAssembly(),
        LarkSceneManagerAssembly(),
        BGTaskSchedulerAssembly(),
        URLInterceptorAssembly(),
        VoteAssembly(),
        LarkSecurityComplianceAssembly(),
        VideoDirectorAssembly(),
        LarkMentionAssembly(),
        LarkStorageAssembly(),
        LarkCleanAssembly(),
        LarkIMMentionAssembly(),
        LarkGeckoTTNetAssembly(),
        LarkPageInAssembly(),
        LarkContactComponentAssembly(),
        PreloadAssembly(),
        EnterpriseNoticeAssembly(),
        LarkDowngradeAssembly(),
        LarkDocsIconAssembly(),
        LarkIconAssembly(),
        FormsAssembly(),
        LarkInlineAIAssemble(),
        WebAppAssemble()
    ]
    #if canImport(LarkFeedback)
    list.append(FeedbackAssembly())
    #endif
    #if canImport(LarkCodeCoverage)
    list.append(LarkCodeCoverageAssembly())
    #endif
    #if canImport(LarkKAExpiredObserver)
    list.append(KAExpiredObserverAssembly())
    #endif
    #if canImport(KAEMMServiceIMP)
    list.append(KAAssembly())
    #endif
    #if canImport(LKAppLinkExternalAssembly)
    list.append(LKNativeAssembly())
    #endif
    #if canImport(LKMenusExternalAssembly)
    list.append(LKMenusExternalAssembly())
    #endif
    #if canImport(LKJsApiExternalAssembly)
    list.append(LKJsApiAssembly())
    #endif
    #if canImport(LKKeyValueExternalAssembly)
    list.append(LKKAKeyValueAssembly())
    #endif
    #if canImport(LKLifecycleExternalAssembly)
    list.append(LKLifecycleExternalAssembly())
    #endif
    #if canImport(LKQRCodeExternalAssembly)
    list.append(LKQRCodeExternalAssembly())
    #endif
    #if canImport(LKStatisticsExternalAssembly)
    list.append(LKStatisticsExternalAssembly())
    #endif
    #if canImport(MeegoMod)
    list.append(FlutterContainerAssembly())
    list.append(MeegoAssembly())
    #endif
    #if canImport(LKPassportExternalAssembly)
    list.append(LKPassportExternalAssembly())
    #endif
    #if canImport(LKSettingExternalAssembly)
    list.append(LKSettingExternalAssembly())
    #endif
    #if canImport(LKLoggerExternalAssembly)
    list.append(LKLoggerExternalAssembly())
    #endif
    #if canImport(LKPassportOperationExternalAssembly)
    list.append(LKPassportOperationExternalAssembly())
    #endif
    #if canImport(LarkKAEMM)
    list.append(KAEMMAssembly())
    #endif
    #if canImport(UDDebug)
    list.append(UDDebugAssembly())
    #endif
    #if canImport(LKMessageExternalAssembly)
    list.append(LKMessageExternalAssembly())
    #endif
    list.append(CTADialogDebugAssembly())
    list.append(LarkNotificationAssembly())
    #if canImport(LarkShortcutAssembly)
    list.append(LarkShortcutAssembly())
    #endif
    return list
}()

fileprivate let minimumAssemblyInteraces: [LarkAssemblyInterface] = [
    LarkAccountAssembly(miniMode: true),
    RustClientAssembly(),
    ConfigAssembly(),
    SettingAssembly(),
    MinimumAssembly()
]

#if canImport(KAEMMServiceIMP)
extension Container: LarkKAContainer {
    public func ka_register<Service>(_ serviceType: Service.Type, factory: @escaping (LarkKAContainer) -> Service) {
        print("Container start register \(serviceType)")
        register(serviceType) { _ in
            factory(self)
        }
    }

    public func ka_resolve<Service>(_ serviceType: Service.Type) -> Service? {
        print("Container start resolve \(serviceType)")
        return resolve(serviceType)
    }
}

fileprivate class KAAssembly: LarkAssemblyInterface {
    let asemmbly = LarkKAEMMServiceAssembly()
    init() {
        print("LarkKAEMMServiceAssembly start register conatainer")
        asemmbly.ka_registContainer(container: BootLoader.container)
        print("LarkKAEMMServiceAssembly finish register conatainer")
    }
}
#endif
