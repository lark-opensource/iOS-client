//
//  LarkNavigationAssembly.swift
//  LarkNavigation
//
//  Created by Meng on 2019/10/21.
//

import UIKit
import AnimatedTabBar
import Foundation
import Swinject
import LarkSetting
import LarkAccountInterface
import LarkContainer
import LarkNavigator
import LarkDebugExtensionPoint
import LarkRustClient
import RunloopTools
import AppContainer
import RxSwift
import EENavigator
import LarkLeanMode
import LarkReleaseConfig
import LarkTraitCollection
import LarkKeepAlive
import BootManager
import LarkUIKit
import RustPB
import LarkSceneManager
import LarkBadge
import LarkStorage
import LarkAssembler
import LarkCloudScheme
import LarkQuickLaunchInterface
import LarkTab

public typealias NavigationDependency = LarkNaviBarDataServiceDependency
    & NavigationServiceImplDependency
    & NavigationApplicationBadgeDependency
    & NavigationTabRepresentableServiceDependency
    & NavigationSearchDependency

public protocol NavigationApplicationBadgeDependency {
    func updateBadge(to count: Int)
}

public protocol LarkNaviBarDataServiceDependency {
    var shouldNoticeNewVerison: Observable<Bool> { get }
}

public protocol NavigationTabRepresentableServiceDependency {
    func createOPAppTabRepresentable(tab: Tab) -> TabRepresentable
}

public final class NavigationAssembly: LarkAssemblyInterface {

    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)

        container.register(TabbarService.self) { _ in
            return RootNavigationController.shared
        }

        user.register(TemporaryTabService.self) { resolver in
            return TemporaryTabManager(resolver: resolver)
        }

        user.register(PageKeeperService.self) { resolver in
            return PageKeeperManager(userResolver: resolver)
        }

        container.register(TabBarLauncherDelegateService.self) { _ in
            return TabbarDelegate(resolver: container)
        }

        container.register(UserSpaceService.self) { (_) -> UserSpaceService in
            let userSpace = UserSpace.shared
            userSpace.getCurrentUserID = { AccountServiceAdapter.shared.currentChatterId }
            return userSpace
        }

        user.register(NavigationService.self) { (resolver) -> NavigationService in
            let navigationConfigService = try resolver.resolve(assert: NavigationConfigService.self)
            let navigationDependency = try resolver.resolve(assert: NavigationDependency.self)
            return NavigationServiceImpl(
                userResolver: resolver,
                navigationConfigService: navigationConfigService,
                dependency: navigationDependency)
        }

        user.register(NavigationConfigService.self) { (resolver) -> NavigationConfigService in
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad 支持自定义 sizeClass
                RootTraitCollection.shared.useCustomSizeClass = true
            }
            let passportUserService = try resolver.resolve(assert: PassportUserService.self)
            let fg = try resolver.resolve(assert: FeatureGatingService.self)
            let appCenterEnable: Bool = passportUserService.user.type != .c
            let pushCenter = try resolver.userPushCenter
            return NavigationConfigService(
                userResolver: resolver,
                appCenterEnable: appCenterEnable,
                pushCenter: pushCenter,
                featureGatingService: fg,
                dependency: try resolver.resolve(assert: NavigationDependency.self))
        }

        user.register(TabbarLifecycle.self) { (_) -> TabbarLifecycle in
            return MainTabbarLifecycleImp()
        }

        user.register(MainTabbarLifecycle.self) { (resolver) -> MainTabbarLifecycle in
            return try resolver.resolve(assert: TabbarLifecycle.self)
        }

        user.register(NavigationAPI.self) { (resolver) -> NavigationAPI in
            return NavigationAPIImpl(userResolver: resolver)
        }

        user.register(SwitchAccountService.self) { (r) -> SwitchAccountViewModel in
            return SwitchAccountViewModel(userResolver: r)
        }

        user.register(QuickLaunchService.self) { (r) -> QuickLaunchService in
            return QuickLaunchManager(userResolver: r)
        }

        container.register(LeanModeDependency.self) { _ -> LeanModeDependency in
            return LeanModeDependencyImp()
        }
    }

    public func registRouter(container: Container) {
        setupRouter(container: container)

        Navigator.shared.registerRoute.type(SideBarBody.self)
        .factory(SideBarHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SideBarFilterBody.self)
        .factory(SideBarFilterHandler.init(resolver:))
    }

    private func setupRouter(container: Container) -> Router {
        SceneManager.shared.registerMain { window in
            let r = container.getCurrentUserResolver(compatibleMode: false) // swiftlint:disable:this all
            return HomeFactory(userResolver: r).create(on: window)
        }

        SceneManager.shared.maxNumber = {
            let resolver = container.getCurrentUserResolver(compatibleMode: false)

            if let setting = try? resolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "ipad_scene_manage")),
               let maxNumber = setting["active_number"] as? Int {
                return maxNumber
            }
            return nil
        }

        Navigator.shared.featureGatingProvider = { key in
            let resolver = container.getCurrentUserResolver(compatibleMode: false)
            return resolver.fg.dynamicFeatureGatingValue(with: .init(stringLiteral: key))
        }

        Navigator.shared.navigationProvider = {
            return RootNavigationController.shared
        }

        Navigator.shared.tabProvider = {
            return RootNavigationController.shared
        }

        Navigator.shared.defaultSchemesBlock = { CloudSchemeManager.shared.supportedHostSchemes }
        return Navigator.shared
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(SetupMainTabTask.self)
        NewBootManager.register(BlockLaunchTask.self)
        NewBootManager.register(PreloadTabServiceTask.self)
        NewBootManager.register(AnalysisFirstTabTask.self)
        NewBootManager.register(SetupLauncherTask.self)
    }

    public func registDebugItem(container: Container) {
        ({ IPadFeatureSwitchDebugItem() }, SectionType.debugTool)
        ({ CustomNaviDebutItem(resolver: container) }, SectionType.debugTool)
        ({ ShowNavigationGuide() }, SectionType.debugTool)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushNavigationAppInfo, NavigationPushHandler.init(resolver:))
        (Command.pushAccountBadgeCount, AccountBadgePushHandler.init(resolver:))
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory(delegateProvider: {
            container.resolve(TabBarLauncherDelegateService.self)!
        }), LauncherDelegateRegisteryPriority.middle)
    }
}

public protocol NavigationSearchDependency: AnyObject {
    func getSearchVC(fromTabURL: URL?, sourceOfSearchStr: String?, entryAction: String) -> UIViewController?
    func getSearchOnPadEntranceView() -> UIView
    func changeSelectedState(isSelect: Bool)
    func enableUseNewSearchEntranceOnPad() -> Bool
}



