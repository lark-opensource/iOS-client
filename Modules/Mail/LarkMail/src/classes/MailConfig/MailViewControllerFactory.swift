//
//  MailViewControllerFactory.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/5/15.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import LarkUIKit
import LarkAppResources
import MailSDK
import RxRelay
import LarkNavigation
import AnimatedTabBar
import LarkTab
import LKCommonsLogging

protocol MailViewControllerFactoryDelegate: AnyObject {
    func willCreateMailTabController(factory: MailViewControllerFactory)
    func didCreateMailTabController(factory: MailViewControllerFactory, tabController: MailTabBarController)
}

/// 用于创建Mail里面的各种ViewController的类，目前仅有邮件Tab。
final class MailViewControllerFactory {
    weak var delegate: MailViewControllerFactoryDelegate?
    let innerFactory: MailSDKManager // 实际创建还是在MailSDK内部做的。

    init(factory: MailSDKManager) {
        innerFactory = factory
    }

    func createMailTabController() -> MailTabBarController & TabRootViewController {
        delegate?.willCreateMailTabController(factory: self)
        let vc: MailTabBarController = innerFactory.makeMailTabController()
        delegate?.didCreateMailTabController(factory: self, tabController: vc)
        return vc as MailTabBarController & TabRootViewController
    }
}

class MailTab: TabRepresentable {
    static let logger = Logger.log(MailTab.self, category: "Module.Mail")

    var tab: Tab { return .mail }

    private var _badge = BehaviorRelay<LarkTab.BadgeType>(value: .none)
    private var _badgeOutsideVisable = BehaviorRelay<Bool>(value: false)
    private var _badgeStyle = BehaviorRelay<BadgeRemindStyle>(value: .strong)

    // badge
    var badge: BehaviorRelay<LarkTab.BadgeType>? {
        return self._badge
    }

    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        // 红色数字、灰色数字 目前都是这个Style
        return _badgeStyle
    }

    var badgeOutsideVisiable: BehaviorRelay<Bool>? {
        return _badgeOutsideVisable
    }

    // 更新 badge 数量
    func updateBadge(_ badge: LarkTab.BadgeType) {
        Self.logger.info("[NavigationTabBadge] MailTab update badge: \(badge.description)")
        _badge.accept(badge)

        switch badge {
        case .number, .image: _badgeStyle.accept(.strong)
        case .dot(let value):
            if value == 0 {
                Self.logger.info("[NavigationTabBadge] MailTab update badge style: strong")
                _badgeStyle.accept(.strong)
            } else {
                Self.logger.info("[NavigationTabBadge] MailTab update badge style: weak")
                _badgeStyle.accept(.weak)
            }
        default: break
        }
        if case .number(let number) = badge, number > 0 {
            Self.logger.info("[NavigationTabBadge] MailTab update badge OutsideVisable: true")

            _badgeOutsideVisable.accept(true)
        } else {
            _badgeOutsideVisable.accept(false)
        }
    }
}

extension MailTabBarController: TabRootViewController {
    public var tab: Tab {
        return Tab.mail
    }

    public var controller: UIViewController {
        return self
    }

    public var firstScreenDataReady: BehaviorRelay<Bool>? {
        return firstScreenObserver.firstScreenDataReady()
    }
}

extension MailTabBarController: TabbarItemTapProtocol {
    public func onTabbarItemTap(_ isSameTab: Bool) {}
    public func onTabbarItemDoubleTap() {
        didReceiveDoubleTabEvent()
    }
}
