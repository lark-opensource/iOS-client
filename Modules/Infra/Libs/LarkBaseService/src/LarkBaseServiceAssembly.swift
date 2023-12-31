//
//  LarkAssembly.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2018/4/19.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import AppContainer
import LKCommonsLogging
import LarkTracker
import LarkFeatureSwitch
import Swinject
import LarkAppConfig
import LarkFeatureGating
import EENavigator
import LarkDebug
import LarkDebugExtensionPoint
import LarkAccountInterface
import RoundedHUD
import LKCommonsTracker
import BootManager
import LarkCache
import CookieManager
import LarkEnv
import LarkAssembler
import LarkSetting
import LarkSplitViewController

// MARK: - Assembly
public final class LarkBaseServiceAssembly: LarkAssemblyInterface {

    static let log = LKCommonsLogging.Logger.log(
        LarkBaseServiceAssembly.self,
        category: "Lark.base.service.assembly")

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(SetupMonitorTask.self)
        NewBootManager.register(UpdateMonitorTask.self)
        NewBootManager.register(SetupAlogTask.self)
        NewBootManager.register(SetupSlardarTask.self)
        NewBootManager.register(SetupLoggerTask.self)
        NewBootManager.register(SetupICloudTask.self)
        NewBootManager.register(SetupURLProtocolTask.self)
        NewBootManager.register(OrientationTask.self)
        NewBootManager.register(SetupDispatcherTask.self)
        NewBootManager.register(TroubleKillerTask.self)
        NewBootManager.register(ABTestSetupTask.self)
        NewBootManager.register(UpdateABTestTask.self)
        NewBootManager.register(OfflineResourceTask.self)
        NewBootManager.register(UpdateOfflineResource.self)
        NewBootManager.register(ExtensionUpdateTask.self)
        NewBootManager.register(ObservePasteboardTask.self)
        NewBootManager.register(ResourceSetupTask.self)
        NewBootManager.register(ThemeSetupTask.self)
        NewBootManager.register(SetupSafetyTask.self)
        NewBootManager.register(SetupCanvasCacheTask.self)
        NewBootManager.register(SetupFileTask.self)
        NewBootManager.register(StartTrafficOfLauncherTask.self)
        NewBootManager.register(HeartBeatTask.self)
        NewBootManager.register(SilentModeTask.self)
        NewBootManager.register(SetupMacTask.self)
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            container.whenLauncherDelegate { container.resolve(LarkMonitorDelegate.self)! } // Global
        }, LauncherDelegateRegisteryPriority.middle)
        (LauncherDelegateFactory {
            container.whenLauncherDelegate { container.resolve(ExtensionConfigDelegate.self)! } // Global
        }, LauncherDelegateRegisteryPriority.middle)
        (LauncherDelegateFactory {
            container.whenLauncherDelegate { container.resolve(ABTestLaunchDelegate.self)! } // Global
        }, LauncherDelegateRegisteryPriority.low)
        (LauncherDelegateFactory {
            container.whenLauncherDelegate { container.resolve(CookieServiceDelegate.self)! } // Global
        }, LauncherDelegateRegisteryPriority.low)
        (LauncherDelegateFactory {
            container.whenLauncherDelegate { container.resolve(ObservePasteboardLauncherDelegate.self)! } // Global
        }, LauncherDelegateRegisteryPriority.middle)
        (LauncherDelegateFactory {
             container.whenLauncherDelegate { container.resolve(HeartBeatLauncherDelegate.self)! } // Global
        }, LauncherDelegateRegisteryPriority.high)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            container.whenPassportDelegate { container.resolve(LarkMonitorDelegate.self)! } // Global
        }, PassportDelegatePriority.middle)
        (PassportDelegateFactory {
            container.whenPassportDelegate { container.resolve(ExtensionConfigDelegate.self)! } // Global
        }, PassportDelegatePriority.middle)
        (PassportDelegateFactory {
            container.whenPassportDelegate { container.resolve(ABTestLaunchDelegate.self)! } // Global
        }, PassportDelegatePriority.low)
        (PassportDelegateFactory {
            container.whenPassportDelegate { container.resolve(CookieServiceDelegate.self)! } // Global
        }, PassportDelegatePriority.low)
        (PassportDelegateFactory {
            container.whenPassportDelegate { container.resolve(ObservePasteboardLauncherDelegate.self)! } // Global
        }, PassportDelegatePriority.middle)
        (PassportDelegateFactory(delegateProvider: {
            container.whenPassportDelegate { container.resolve(HeartBeatPassportDelegate.self)! } // Global
        }), PassportDelegatePriority.high)
    }

    public func registContainer(container: Container) {
        let global = container.inObjectScope(.container)

        global.register(TrackService.self) { (_) -> TrackService in
            var traceUserInterfaceIdiom: Bool = false
            Feature.on(.tracerUserInterfaceIdiom).apply(on: {
                traceUserInterfaceIdiom = true
            }, off: {
                traceUserInterfaceIdiom = false
            })

            return TrackService(
                traceUserInterfaceIdiom: traceUserInterfaceIdiom,
                isStaging: EnvManager.env.isStaging,
                isRelease: EnvManager.env.type == .release
            )
        }

        global.register(HeartBeatPassportDelegate.self) { _ -> HeartBeatPassportDelegate in
            return HeartBeatPassportDelegate()
        }

        global.register(HeartBeatLauncherDelegate.self) { _ -> HeartBeatLauncherDelegate in
            return HeartBeatLauncherDelegate()
        }
        global.register(LarkMonitorDelegate.self) { LarkMonitorDelegate(resolver: $0) }
        global.register(ExtensionConfigDelegate.self) { ExtensionConfigDelegate(resolver: $0) }
        global.register(ABTestLaunchDelegate.self) { ABTestLaunchDelegate(resolver: $0) }
        global.register(OfflineResourceDelegate.self) { OfflineResourceDelegate(resolver: $0) }
        global.register(CookieServiceDelegate.self) { CookieServiceDelegate(resolver: $0) }
        global.register(ObservePasteboardLauncherDelegate.self) { ObservePasteboardLauncherDelegate(resolver: $0) }
    }

    public func registRouter(container: Container) {
        getRouter(container: container)

        Navigator.shared.registerMiddleware_(postRoute: false, cacheHandler: true) { () -> MiddlewareHandler in
            return URLMapHandler()
        }
    }

    private func getRouter(container: Container) -> Router {
        // 路由添加页面跳转打点
        let navigatorTimeTracker: NavigatorTimeTracker = { (from, to, navigatorType, time) in
            var type = ""
            switch navigatorType {
            case .unknow:
                type = "unknow"
            case .push:
                type = "push"
            case .present:
                type = "present"
            case .showDetail:
                type = "showDetail"
            case .didAppear:
                type = "didAppear"
            @unknown default:
                assert(false, "new value")
                type = "unknow"
            }

            let metric: [String: Any] = ["cost": time]
            let category: [String: Any] = [
                "fromVC": from,
                "toVC": to,
                "type": type
            ]
            Tracker.post(SlardarEvent(
                name: "lark_navigator_cost",
                metric: metric,
                category: category,
                extra: [:])
            )
        }
        Navigator.shared.updateNavigatorTimeTracker(navigatorTimeTracker)

        return Navigator.shared.registerMiddleware_(postRoute: true) { _, res in
            if res.error != nil, let window = Navigator.shared.mainSceneWindow {
                RoundedHUD.showFailure(with: BundleI18n.Lark.Lark_Legacy_UnrecognizedLink, on: window)
            }
        }
    }

    public func registBootLoader(container: Container) {
        (MonitorApplicationDelegate.self, DelegateLevel.high)
        (URLProtocolApplicationDelegate.self, DelegateLevel.high)
        (HeartBeatApplicationDelegate.self, DelegateLevel.default)
        (ContinueUserActivityApplicationDelegate.self, DelegateLevel.default)
        (SceneApplicationDelegate.self, DelegateLevel.default)
        (LarkBadgeApplicationDelegate.self, DelegateLevel.default)
        (OfflineResourceApplicationDelegate.self, DelegateLevel.default)
        (SilentModeApplicationDelegate.self, DelegateLevel.default)
    }
    // swiftlint:enable function_body_length

    public func registDebugItem(container: Container) {
        ({ DynamicDebugItem() }, SectionType.debugTool)
        ({ MemoryGraphDebugItem() }, SectionType.debugTool)
        #if !LARK_NO_DEBUG
        ({ ETTrackerDebugItem() }, SectionType.debugTool)
        #endif
    }
}

enum LarkBaseService {
    static var userScopeCompatibleMode: Bool {
        // 兼容回滚的FG，默认不兼容，按需添加回滚
        FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.baseservice.compatible")
    }
}
