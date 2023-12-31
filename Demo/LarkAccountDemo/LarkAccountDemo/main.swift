//
//  main.swift
//  LarkAccountDemo
//
//  Created by Supeng on 2021/1/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import RxSwift
import Swinject
import LarkPerf
import BootManager
import AppContainer
import LarkContainer
import LarkLocalizations

var platformAssemblies: [Assembly] = []

// NOTE: Please import in alphabet order.

#if canImport(Blockit)
import Blockit
platformAssemblies.append(BlockitAssembly())
#endif

#if canImport(BlockitAssembly)
import BlockitAssembly
platformAssemblies.append(BlockitAssembly())
#endif

#if canImport(LarkAccount)
import LarkAccount
platformAssemblies.append(DefaultAccountDependencyAssembly())
platformAssemblies.append(AccountAssembly())
#endif

#if canImport(LarkAppConfig)
import LarkAppConfig
platformAssemblies.append(ConfigAssembly())
#endif

#if canImport(LarkAppLinkSDK)
import LarkAppLinkSDK
platformAssemblies.append(AppLinkAssembly())
#endif

#if canImport(LarkBanner)
import LarkBanner
platformAssemblies.append(LarkBannerAssembly())
#endif

#if canImport(LarkBaseService)
import LarkBaseService
platformAssemblies.append(LarkBaseServiceAssembly())
#endif

#if canImport(LarkCloudScheme)
import LarkCloudScheme
platformAssemblies.append(CloudSchemeAssembly())
#endif

#if canImport(LarkDebug)
import LarkDebug
platformAssemblies.append(LarkDebug.DebugAssembly())
#endif

#if canImport(LarkEmotion)
import LarkEmotion
platformAssemblies.append(EmotionAssembly())
#endif

#if canImport(LarkGuide)
import LarkGuide
platformAssemblies.append(LarkGuideAssembly())
#endif

#if canImport(LarkKASDKAssemble)
import LarkKASDKAssemble
platformAssemblies.append(KATabAssembly())
#endif

#if canImport(LarkLaunchGuide)
import LarkLaunchGuide
platformAssemblies.append(LaunchGuideAssembly())
platformAssemblies.append(DefaultLaunchGuideDependencyAssembly())
#endif

#if canImport(LarkLeanMode)
import LarkLeanMode
platformAssemblies.append(LeanModeAssembly())
#endif

#if canImport(LarkMagic)
import LarkMagic
platformAssemblies.append(MagicAssembly())
#endif

#if canImport(LarkMinimumMode)
import LarkMinimumMode
platformAssemblies.append(MinimumAssembly())
#endif

#if canImport(LarkNavigation)
import LarkNavigation
platformAssemblies.append(NavigationAssembly())
platformAssemblies.append(NavigationMockAssembly())
#endif

#if canImport(LarkPushTokenUploader)
import LarkPushTokenUploader
platformAssemblies.append(LarkPushTokenUploaderAssembly())
#endif

#if canImport(LarkRustClientAssembly)
import LarkRustClientAssembly
platformAssemblies.append(RustClientAssembly())
#endif

#if canImport(LarkSetting)
import LarkSetting
platformAssemblies.append(SettingAssembly())
#endif

#if canImport(LarkSecurityAudit)
import LarkSecurityAudit
platformAssemblies.append(SecurityAuditAssembly())
#endif

#if canImport(LarkSettingsBundle)
import LarkSettingsBundle
platformAssemblies.append(SettingsBundleAssembly())
#endif

#if canImport(LarkShareContainer)
import LarkShareContainer
platformAssemblies.append(LarkShareContainerAssembly())
#endif

#if canImport(LarkSnsShare)
import LarkSnsShare
platformAssemblies.append(LarkSnsShareAssembly())
platformAssemblies.append(LarkSnsShareBaseAssembly())
#endif

#if canImport(LarkSuspendable)
import LarkSuspendable
platformAssemblies.append(SuspendAssembly())
#endif

#if canImport(LarkTour)
import LarkTour
platformAssemblies.append(TourAssembly())
platformAssemblies.append(DefaultLarkTourDependencyAssembly())
#endif

#if canImport(LarkWaterMark)
import LarkWaterMark
platformAssemblies.append(WaterMarkAssembly())
#endif

#if canImport(SuiteAppConfig)
import SuiteAppConfig
platformAssemblies.append(SuiteAppConfigAssembly())
#endif

#if canImport(TangramService)
import TangramService
platformAssemblies.append(TangramAssembly())
#endif

#if canImport(UGReachSDK)
import UGReachSDK
platformAssemblies.append(ReachSDKAssembly())
#endif

#if canImport(LarkVersionAssembly)
import LarkVersionAssembly
platformAssemblies.append(LarkVersionAssembly())
#endif

var moduleAssemblies: [Assembly] = []
#if canImport(CalendarMod)
import CalendarMod
moduleAssemblies.append(LarkCalendarAssembly())
#endif

#if canImport(TodoMod)
import TodoMod
import Todo
moduleAssemblies.append(TodoModAssembly())
moduleAssemblies.append(TodoAssembly())
#endif

#if canImport(MessengerMod)
import MessengerMod
import LarkMine
moduleAssemblies.append(ThemeAssembly())
moduleAssemblies.append(MessengerAssembly())
#endif

#if canImport(ByteViewMod)
import ByteViewMod
moduleAssemblies.append(LarkByteViewAssembly())
#endif

#if canImport(MinutesMod)
import MinutesMod
moduleAssemblies.append(LarkMinutesAssembly())
#endif

#if canImport(CCMMod)
import CCMMod
moduleAssemblies.append(SpaceKitAssemble())
#endif

final class NewLarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        _ = Assembler(platformAssemblies + moduleAssemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true

        DispatchQueue.global().async {
            (platformAssemblies + moduleAssemblies).forEach { assemble in
                assemble.asyncAssemble()
            }
        }
    }
}

func larkMain() {
    // swiftlint:disable all
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable all

    ColdStartup.shared?.do(.main)
    AppStartupMonitor.shared.start(key: .startup)

    NewBootManager.register(NewLarkMainAssembly.self)
    NewBootManager.register(SetupMainTabTask.self)

    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
}

class SetupMainTabTask: FlowBootTask, Identifiable {
    static var identify = "SetupMainTabTask"

    override func execute(_ context: BootContext) {
        let vc = UIViewController()
        vc.view.backgroundColor = .red
        context.window?.rootViewController = vc
    }
}

larkMain()
