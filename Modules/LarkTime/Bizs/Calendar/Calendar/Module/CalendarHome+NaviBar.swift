//
//  HomeViewController.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/25.
//

import UIKit
import Foundation
import RxCocoa
import EENavigator
import CalendarFoundation
import LarkUIKit
import LarkNavigation
import AnimatedTabBar
import LarkTab

extension CalendarViewController: LarkNaviBarDataSource {

    public var isDrawerEnabled: Bool {
        return true
    }

    // 显示统一导航栏
    public var isNaviBarEnabled: Bool {
        return true
    }
    // Title
    public var titleText: BehaviorRelay<String> {
        return naviHeaderTitle
    }

    public var naviButtonView: UIView? {
        if Display.pad, traitCollection.horizontalSizeClass == .regular {
            return iPadNaviView
        } else {
            return nil
        }
    }

    public func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        switch type {
        case .search:
            return nil
        case .first:
            return nil
        case .second:
            return nil
        }
    }

    public var isDefaultSearchButtonDisabled: Bool {
        return !isAllowSearch
    }
}

extension CalendarViewController: LarkNaviBarDelegate {
    public func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .search:
            calendarDependency?.jumpToMainSearchController(from: self)
        default: break
        }
    }
}
