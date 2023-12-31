//
//  ByteViewBaseTabViewController.swift
//  ByteView
//
//  Created by chentao on 2021/3/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxRelay

public class ByteViewBaseTabViewController: UIViewController {
    public var userId: String { "" }

    public var larkNavibarBgColor: UIColor? { nil }

    public func handleTabbarItemDoubleTap() {}

    public func handleTabbarItemTap(_ isSameTab: Bool) {}

    public func willSwitchToTabBar() {}

    public func didSwitchToTabBar() {}

    public func willSwitchOutTabBar() {}

    public func didSwitchOutTabBar() {}

    public func clearTabBadgeUnreadCount() {}

    public func didTapSearchButton() {}

    public var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: I18n.View_MV_MeetingsTab)
    }

    public var isNaviBarEnabled: Bool { !traitCollection.isRegular }

    public var isNewTabEnabled: Bool { false }

    public var isDrawerEnabled: Bool { true }

    public var isDefaultSearchButtonDisabled: Bool { true }

    public var naviBarSearchButton: UIButton? { nil }

    public var naviBarButton: UIButton? { nil }
}

public protocol LarkMainViewController {

    var larkNavigationBarHeight: CGFloat { get }

    var larkTabBarHeight: CGFloat? { get }

    func changeLarkNavigationBarPresentation(show: Bool?, animated: Bool)

    func reloadLarkNavigationBar()

    var isLarkNaviBarShown: Bool { get }
}

extension ByteViewBaseTabViewController {

    var larkMainViewController: LarkMainViewController? {
        return self as? LarkMainViewController
    }
}
