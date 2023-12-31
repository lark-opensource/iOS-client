//
//  LarkInterface+Navigation.swift
//  LarkInterface
//
//  Created by Meng on 2019/10/20.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LarkAccountInterface
import AnimatedTabBar
import LarkTab

public protocol TabBarLauncherDelegateService: LauncherDelegate {}

public protocol NavigationService: AnyObject {
    /// customNavi feature gating
    var customNaviEnable: Bool { get }

    /// 需要用到tabbarStyle，返回不同style下的数据
    var tabbarStyle: TabbarStyle { get set }

    /// main和edge下的tabs
    var allTabs: AllTabs { get }

    /// if isCustomNaviEnable fg close, use legacy tab urls for mainTab, qucikTab return empty array.
    var mainTabs: [Tab] { get }

    /// quick tab config & order
    var quickTabs: [Tab] { get }

    /// Tabs not in main & quick
    var locoalTabs: [Tab] { get }

    /// to get first Tab in Main
    var firstTab: Tab? { get }

    /// tab切换的信号
    var tabDriver: Driver<(oldTab: Tab?, newTab: Tab?)> { get }

    /// 是否有update tab notice
    /// height: the notice view height
    var tabNoticeShowDriver: Driver<CGFloat> { get }
}

extension NavigationService {

    /// check tab enable to switch
    /// - Parameter tab: Tab
    public func checkSwitchTabEnable(for tab: Tab) -> Bool {
        return locoalTabs.contains(tab)
    }

    /// check given `tab` is in `mainTabs` or `quickTabs`
    public func checkInTabs(for tab: Tab) -> Bool {
        return checkInMainTabs(for: tab) || checkInQuickTabs(for: tab)
    }

    public func checkInMainTabs(for tab: Tab) -> Bool {
        return mainTabs.contains(tab)
    }

    public func checkInQuickTabs(for tab: Tab) -> Bool {
        return quickTabs.contains(tab)
    }

    /// is Target Tab in first place
    /// - Parameter tab: target Tab
    public func isFirstTab(tab: Tab?) -> Bool {
        return firstTab == tab && firstTab != nil
    }
}

public protocol TabbarService {
    func badgeDriver(for tab: Tab) -> Driver<LarkTab.BadgeType>
}
