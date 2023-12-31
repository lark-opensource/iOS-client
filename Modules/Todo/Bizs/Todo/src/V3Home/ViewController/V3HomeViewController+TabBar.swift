//
//  V3HomeViewController+TabBar.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/25.
//

import Foundation
import AnimatedTabBar
import LarkTab
import RxCocoa

// MARK: - Home - Tab

extension V3HomeViewController: TabRootViewController {
    var tab: Tab { .todo }
    var controller: UIViewController { self }
    /// 首屏数据Ready
    var firstScreenDataReady: BehaviorRelay<Bool>? { nil }

    var deallocAfterSwitchTab: Bool { Utils.DeviceStatus().isLowDevice }
}

extension V3HomeViewController: TabbarItemTapProtocol {
    func onTabbarItemTap(_ isSameTab: Bool) {
        settingService?.fetchDataIfNeeded()
    }
}
