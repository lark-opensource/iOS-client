//
//  HomeFactory.swift
//  Lark
//
//  Created by 姚启灏 on 2018/6/24.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import AnimatedTabBar
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import Swinject
import EENavigator
import AppContainer
import LarkAppResources
import LarkAccountInterface
import RunloopTools
import LarkGuide
import LarkLeanMode
import LarkTab
import LarkSetting
import LarkFeatureGating
import SuiteAppConfig

final class HomeFactory: UserResolverWrapper {
    private var navigationService: NavigationService?

    @ScopedInjectedLazy var fgService: FeatureGatingService?

    private static let logger = Logger.log(HomeFactory.self, category: "LarkNavigation.HomeFactory")

    let userResolver: UserResolver

    // FG：CRMode数据统一
    public lazy var crmodeUnifiedDataDisable: Bool = {
        return fgService?.staticFeatureGatingValue(with: "lark.navigation.disable.crmode") ?? false
    }()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.navigationService = try? userResolver.resolve(assert: NavigationService.self)
    }

    func create(on newWindow: UIWindow) -> UIViewController {
        let tab = generateTab()
        RootNavigationController.shared.reset(with: tab)
        let home = RootNavigationController.shared
        if home.isViewLoaded {
            if let oldWindow = home.currentWindow(), oldWindow.rootViewController == home {
                // 当原来的 scene rootViewController 也是 home 时，需要避免两个 scene 都持有 home
                if home.presentedViewController != nil {
                    // 当原来的 scene 有 presentedVC 时，需要 dismiss 以防卡死
                    Self.recursivelyDismiss(for: home, finalCompletion: {
                        oldWindow.rootViewController = Self.whiteEmptyVC()
                        // https://developer.apple.com/forums/thread/105618
                        // 当有VC在动画过程中，设置导航栈会失败，此处做一个补偿设置
                        if home.viewControllers != [tab] {
                            home.reset(with: tab)
                        }
                        newWindow.rootViewController = home
                    })
                    // 暂时返回一个空 VC，home 会在 dismissCompletion 中替换新 window 的 rootVC
                    return Self.whiteEmptyVC()
                }
                // 因为暂不支持多主 Scene，如果在已经有主 Scene 之后又创建主 Scene，则销毁原来的主 Scene rootVC
                oldWindow.rootViewController = Self.whiteEmptyVC()
            }
        }
        return home
    }

    private class func recursivelyDismiss(for vc: UIViewController, finalCompletion: @escaping () -> Void) {
        if let presentedVC = vc.presentedViewController {
            presentedVC.dismiss(animated: false, completion: {
                Self.recursivelyDismiss(for: vc, finalCompletion: finalCompletion)
            })
        } else {
            finalCompletion()
        }
    }

    private class func whiteEmptyVC() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.ud.bgBase
        return vc
    }

    private func generateTab() -> LkTabbarController {
        let isNewNavigation = !AppConfigManager.shared.leanModeIsOn
        // 注入 FeatureGating
        let tabController = MainTabbarController(
            translucent: true,
            isQuickLauncherEnabled: isNewNavigation,
            userResolver: self.userResolver
        )

        guard let navigationService = self.navigationService else {
            Self.logger.error("resolve navigationService error!")
            return tabController
        }
        if Display.pad {
            // iPad 同步展示，因为 More 按钮的展示与否可能根据 Quick 的数量来判定
            let allItems = navigationService.allTabs.all
                .compactMap {
                    // 这边真是吐了，之前都是业务方注入的，有很多定制逻辑（红点），但是，但是，但是
                    // 现在AppInfo里面多了N多的字段，用来各种定制和交互控制，所以必须以服务端下发的AppInfo为准
                    // 为了不影响原来的逻辑，只能在这边更新tabBarItem里面的tab对象，不能使用业务方自己Provider提供的
                    if let tabBarItem = TabRegistry.resolve($0)?.makeTabItem(userResolver: self.userResolver) {
                        tabBarItem.tab = $0
                        return tabBarItem
                    } else {
                        return nil
                    }
                }
            // CRMode数据统一GA后把后面重复代码删除
            if !self.crmodeUnifiedDataDisable {
                let iPadMainTabs = navigationService.allTabs.iPad.main
                let iPadQuickTabs = navigationService.allTabs.iPad.quick

                tabController.resetTabBarItems(allTabBarItems: allItems)
                tabController.updateMainItemsOrder(iPhoneMainTabs: [], iPadMainTabs: iPadMainTabs)
                tabController.updateQuickItemsOrder(iPhoneQuickTabs: [], iPadQuickTabs: iPadQuickTabs)
                tabController.quickTabInitTask = nil
                tabController.setHardwareKeyboardObserve(enable: true)

                if tabController.tabbarStyle == .bottom {
                    // iPad设备C模式
                    if let firstTab = iPadMainTabs.first {
                        tabController.selectedTab = firstTab
                    }
                } else {
                    // iPad设备R模式
                    if let firstTab = iPadMainTabs.first {
                        tabController.tabItemSelectHandler(for: firstTab)
                    }
                }
            } else {
                let bottomMainTabs = navigationService.allTabs.bottom.main
                let edgeMainTabs = navigationService.allTabs.edge.main
                let bottomQuickTabs = navigationService.allTabs.bottom.quick
                let edgeQuickTabs = navigationService.allTabs.edge.quick

                tabController.resetTabBarItems(allTabBarItems: allItems)
                tabController.updateMainItemsOrder(bottomMainTabs: bottomMainTabs, edgeMainTabs: edgeMainTabs)
                tabController.updateQuickItemsOrder(bottomQuickTabs: bottomQuickTabs, edgeQuickTabs: edgeQuickTabs)
                tabController.quickTabInitTask = nil
                tabController.setHardwareKeyboardObserve(enable: true)

                if tabController.tabbarStyle == .bottom {
                    if let firstTab = bottomMainTabs.first {
                        tabController.selectedTab = firstTab
                    }
                } else {
                    if let firstTab = edgeMainTabs.first {
                        tabController.tabItemSelectHandler(for: firstTab)
                    }
                }
            }
        } else {
            // CRMode数据统一GA后把后面重复代码删除
            if !self.crmodeUnifiedDataDisable {
                // iPhone 上异步生成并加载 Quick Item，提高启动速度
                let iPhoneMainItems = navigationService.allTabs.iPhone.main
                    .compactMap {
                        // 这边真是吐了，之前都是业务方注入的，有很多定制逻辑（红点），但是，但是，但是
                        // 现在AppInfo里面多了N多的字段，用来各种定制和交互控制，所以必须以服务端下发的AppInfo为准
                        // 为了不影响原来的逻辑，只能在这边更新tabBarItem里面的tab对象，不能使用业务方自己Provider提供的
                        if let tabBarItem = TabRegistry.resolve($0)?.makeTabItem(userResolver: self.userResolver) {
                            tabBarItem.tab = $0
                            return tabBarItem
                        } else {
                            return nil
                        }
                    }
                let iPhoneMainTabs = navigationService.allTabs.iPhone.main
                let iPhoneQuickTabs = navigationService.allTabs.iPhone.quick

                tabController.resetTabBarItems(allTabBarItems: iPhoneMainItems)
                tabController.updateMainItemsOrder(iPhoneMainTabs: iPhoneMainTabs, iPadMainTabs: [])

                let quickTabTask = { [weak tabController] in
                    let iPhoneQuickItems = navigationService.allTabs.iPhone.quick
                        .compactMap {
                            // 这边真是吐了，之前都是业务方注入的，有很多定制逻辑（红点），但是，但是，但是
                            // 现在AppInfo里面多了N多的字段，用来各种定制和交互控制，所以必须以服务端下发的AppInfo为准
                            // 为了不影响原来的逻辑，只能在这边更新tabBarItem里面的tab对象，不能使用业务方自己Provider提供的
                            if let tabBarItem = TabRegistry.resolve($0)?.makeTabItem(userResolver: self.userResolver) {
                                tabBarItem.tab = $0
                                return tabBarItem
                            } else {
                                return nil
                            }
                        }
                    tabController?.resetTabBarItems(allTabBarItems: iPhoneMainItems + iPhoneQuickItems)
                    tabController?.updateQuickItemsOrder(iPhoneQuickTabs: iPhoneQuickTabs, iPadQuickTabs: [])
                }
                tabController.quickTabInitTask = quickTabTask
                RunloopDispatcher.shared.addTask(priority: .high, taskAction: quickTabTask)
                
                // 优先展示一方应用或适配了tab打开方式的页面
                if let firstTab = iPhoneMainTabs.first(where: { $0.openMode == .switchMode }) {
                    tabController.selectedTab = firstTab
                } else {
                    // 否则展示「More」页面适配Tab
                    if let first = iPhoneQuickTabs.first(where: { $0.openMode == .switchMode }) {
                        tabController.selectedTab = first
                        tabController.bottomMoreItem?.selectedState()
                    }
                }
            } else {
                // iPhone 上异步生成并加载 Quick Item，提高启动速度
                let bottomMainItems = navigationService.allTabs.bottom.main
                    .compactMap {
                        // 这边真是吐了，之前都是业务方注入的，有很多定制逻辑（红点），但是，但是，但是
                        // 现在AppInfo里面多了N多的字段，用来各种定制和交互控制，所以必须以服务端下发的AppInfo为准
                        // 为了不影响原来的逻辑，只能在这边更新tabBarItem里面的tab对象，不能使用业务方自己Provider提供的
                        if var tabBarItem = TabRegistry.resolve($0)?.makeTabItem(userResolver: self.userResolver) {
                            tabBarItem.tab = $0
                            return tabBarItem
                        } else {
                            return nil
                        }
                    }
                let bottomMainTabs = navigationService.allTabs.bottom.main
                let bottomQuickTabs = navigationService.allTabs.bottom.quick

                tabController.resetTabBarItems(allTabBarItems: bottomMainItems)
                tabController.updateMainItemsOrder(bottomMainTabs: bottomMainTabs, edgeMainTabs: [])

                let quickTabTask = { [weak tabController] in
                    let bottomQuickItems = navigationService.allTabs.bottom.quick
                        .compactMap {
                            // 这边真是吐了，之前都是业务方注入的，有很多定制逻辑（红点），但是，但是，但是
                            // 现在AppInfo里面多了N多的字段，用来各种定制和交互控制，所以必须以服务端下发的AppInfo为准
                            // 为了不影响原来的逻辑，只能在这边更新tabBarItem里面的tab对象，不能使用业务方自己Provider提供的
                            if var tabBarItem = TabRegistry.resolve($0)?.makeTabItem(userResolver: self.userResolver) {
                                tabBarItem.tab = $0
                                return tabBarItem
                            } else {
                                return nil
                            }
                        }
                    tabController?.resetTabBarItems(allTabBarItems: bottomMainItems + bottomQuickItems)
                    tabController?.updateQuickItemsOrder(bottomQuickTabs: bottomQuickTabs, edgeQuickTabs: [])
                }
                tabController.quickTabInitTask = quickTabTask
                RunloopDispatcher.shared.addTask(priority: .high, taskAction: quickTabTask)
                
                // 优先展示一方应用或适配了tab打开方式的页面
                if let firstTab = bottomMainTabs.first(where: { $0.openMode == .switchMode }) {
                    tabController.selectedTab = firstTab
                } else {
                    // 否则展示「More」页面适配Tab
                    if let first = bottomQuickTabs.first(where: { $0.openMode == .switchMode }) {
                        tabController.selectedTab = first
                        tabController.bottomMoreItem?.selectedState()
                    }
                }
            }
        }
        return tabController
    }
}
