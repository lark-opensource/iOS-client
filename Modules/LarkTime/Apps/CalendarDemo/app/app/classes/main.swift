//
//  main.swift
//  CalendarDemo
//
//  Created by heng zhu on 2020/2/4.
//

import UIKit
import LarkContainer
import Swinject
import LarkAccountAssembly
import LarkDebug
import AppContainer
import RxSwift
import LarkAppConfig
import LarkPerf
import LarkAppLinkSDK
import LarkNavigation
import LarkLeanMode
import LarkSnsShare
import LarkAccountInterface
import LarkSettingsBundle
import BootManager
import LarkLocalizations
import LarkSuspendable
import LarkRustClientAssembly
import LarkSetting
import SuiteAppConfig
import LarkEmotion
import LarkLaunchGuide
import LarkKeyCommandKit
import LarkEditorJS
import LarkOPInterface
import ByteWebImage
import RunloopTools
import UniverseDesignTheme
import Calendar
import EEKeyValue
import LarkAssembler
import LKLoadable
import AnimatedTabBar
import EENavigator
import LarkTab
import LarkUIKit
import FLEX
import LarkWebViewContainer
import ECOInfra
import LarkNavigationAssembly
import CookieManager

var platformAssemblies: [LarkAssemblyInterface] = [BaseAssembly()]

#if canImport(LarkTour)
import LarkTour
platformAssemblies.append(TourAssembly())
platformAssemblies.append(DefaultLarkTourDependencyAssembly())
#endif

#if canImport(LarkWaterMark)
import LarkWaterMark
platformAssemblies.append(WaterMarkAssembly())
#endif

#if canImport(LarkGuide)
import LarkGuide
platformAssemblies.append(LarkGuideAssembly())
#endif

#if canImport(LarkBanner)
import LarkBanner
platformAssemblies.append(LarkBannerAssembly())
#endif

#if canImport(LarkSecurityAudit)
import LarkSecurityAudit
platformAssemblies.append(SecurityAuditAssembly())
#endif

#if canImport(LarkShareContainer)
import LarkShareContainer
platformAssemblies.append(LarkShareContainerAssembly())
#endif

#if canImport(UGReachSDK)
import UGReachSDK
platformAssemblies.append(ReachSDKAssembly())
#endif

#if canImport(LarkMinimumMode)
import LarkMinimumMode
platformAssemblies.append(MinimumAssembly())
#endif

#if canImport(TangramService)
import TangramService
platformAssemblies.append(TangramAssembly())
#endif

#if canImport(BlockitAssembly)
import BlockitAssembly
platformAssemblies.append(BlockitAssembly())
#endif

#if canImport(LarkMagic)
import LarkMagic
platformAssemblies.append(MagicAssembly())
#endif

#if canImport(Blockit)
import Blockit
platformAssemblies.append(BlockitAssembly())
#endif

#if canImport(LarkVersionAssembly)
import LarkVersionAssembly
platformAssemblies.append(LarkVersionAssembly())
#endif

var moduleAssemblies: [LarkAssemblyInterface] = []
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
import LarkExtensionCommon
import LarkContact
moduleAssemblies.append(ThemeAssembly())
moduleAssemblies.append(MessengerAssembly())
moduleAssemblies.append(SuiteAppConfigAssembly())
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

#if canImport(LarkQRCode)
import LarkQRCode
moduleAssemblies.append(QRCodeAssembly())
#endif

#if canImport(LarkDialogManager)
import LarkDialogManager
moduleAssemblies.append(DialogManagerAssembly())
#endif

final class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    @Provider private var newGuideManager: NewGuideService

    override func execute(_ context: BootContext) {

        BootLoader.container.register(AppConfiguration.self) { _ in
            return ConfigurationManager.shared
        }.inObjectScope(.container)

        BootLoader.container.register(SubscriptionCenter.self) { _ in
            return SubscriptionCenter()
        }.inObjectScope(.user)

        BootLoader.container.register(LarkWebViewProtocol.self) { _ in
            return LarkWebViewProtocolImpl()
        }.inObjectScope(.user)

        _ = Assembler(assemblies: [], assemblyInterfaces: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true

        CommonJSUtil.unzipIfNeeded()
        OPTraceService.default().setup(OPTraceConfig(prefix: "calendar") { _ in NSUUID().uuidString})

        // register tab
        TabRegistry.register(CalendarDemoTab.mockTab) { _ in CalendarDemoTab() }
        Navigator.shared.registerRoute(plainPattern: CalendarDemoTab.mockTab.urlString, priority: .high) { (_, res) in
            var vc: UIViewController = DemoVC()
            if Display.phone {
                vc = LkNavigationController(rootViewController: vc)
            }
            res.end(resource: vc)
        }

        FLEXManager.shared.registerSimulatorShortcut(withKey: "D", modifiers: [], action: {
            Navigator.shared.present(
                body: DebugBody(),
                wrap: UINavigationController.self,
                from: UIApplication.shared.keyWindow!,
                prepare: { $0.modalPresentationStyle = .fullScreen }
            )
        }, description: "Show Lark Debugger")

        _ = UIApplication.shared.rx.methodInvoked(#selector(UIResponder.motionBegan(_:with:)))
            .subscribe(onNext: { params in
                if let motion = params.first as? Int, motion == 1 {
                    if FLEXManager.shared.isHidden {
                        FLEXManager.shared.showExplorer()
                    }
                }
            })

        NewBootManager.register(SetupDispatcherTask.self)
        NewBootManager.register(SetupLoggerTask.self)

        // 先注释掉 fix每次启动都要登录的问题
        // newGuideManager.fetchUserGuideInfos()
    }

    private let assemblies: [LarkAssemblyInterface] = platformAssemblies + moduleAssemblies
}

func larkMain() {
    RunloopDispatcher.enable = true
    if #available(iOS 13.0, *) {
        UDThemeManager.setUserInterfaceStyle(.unspecified)
    }
//    ConfigurationManager.shared.debugMenuUpdateEnv(Env(type: .staging, unit: "boecn"))
//    BOEConfig.BOEFd = "BOE:hugang"
//    exit(0)
    #if DEBUG
    let result = Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
    print("load \(String(describing: result))")
    #endif
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    LanguageManager.setCurrent(language: Lang(rawValue: "zh_CN"), isSystem: false)
    // swiftlint:enable all
    print("sandbox: \(NSHomeDirectory())")
    signal(SIGPIPE, SIG_IGN)

    KeyCommandKit.addCloseKeyCommands()

    NewBootManager.register(LarkMainAssembly.self)
    BootLoader.shared.start(delegate: AppDelegate.self, config: .default)
}

larkMain()
