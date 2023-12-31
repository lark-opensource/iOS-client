//
//  MinutesHomeViewController+Tap.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/2/24.
//

import UIKit
import Foundation
import RxRelay
import Minutes
import LarkTab
import LarkUIKit
import AnimatedTabBar

extension MinutesHomePageViewController: TabRootViewController {
    public var tab: Tab {
        return Tab.minutes
    }

    public var controller: UIViewController {
        return self
    }
}

extension MinutesHomePageViewController: LarkNaviBarProtocol {
    public var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: MinutesOpenI18n.MinutesNameShort)
    }

    public var isNaviBarEnabled: Bool {
        return true
    }

    public var isDrawerEnabled: Bool {
        return true
    }

    public var isDefaultSearchButtonDisabled: Bool {
        return true
    }

    public func larkNaviBar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? {
        if spaceType == .home {
            switch type {
            case .search:
                return tabSearchButton
            case .first:
                return moreButton
            default:
                return nil
            }
        }
        return nil
    }

    public func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
    }

    public func larkNavibarBgColor() -> UIColor? {
        if traitCollection.horizontalSizeClass == .compact {
            return nil
        } else {
            return UIColor.clear
        }
    }

    public func onTitleViewTapped() {
    }
}

public final class MinutesTab: TabRepresentable {
    public init() {

    }

    public var tab: Tab {
        return Tab.minutes
    }
}
