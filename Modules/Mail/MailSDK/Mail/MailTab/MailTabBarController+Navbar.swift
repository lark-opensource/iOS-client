//
//  MailTabBarController+Navbar.swift
//  MailSDK
//
//  Created by majx on 2020/5/13.
//

import Foundation
import RxRelay
import LarkNavigation
import LarkUIKit
import UIKit

protocol MailNavBarDatasource: AnyObject {
    var navbarTitle: BehaviorRelay<String> { get }
    var navbarSubTitle: BehaviorRelay<String?> { get }
    var navbarShowLoading: BehaviorRelay<Bool> { get }
    var navbarEnable: Bool { get }
    func navbar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage?
    func navbar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton?
    func setNavBarBridge(_ bridge: MailNavBarBridge)
    func customTitleArrowView(titleColor: UIColor) -> UIView?
}

protocol MailNavBarBridge: AnyObject {
    func changeLarkNaviBarTitleArrow(folded: Bool?, animated: Bool)
    func getLarkNaviBar() -> LarkNaviBar?
    func reloadLarkNaviBar()
}

protocol MailNavBarDelegate: AnyObject {
    func onNavTitleTapped()
    func onNavButtonTapped(type: LarkNaviButtonType)
}

extension MailTabBarController: LarkNaviBarDataSource {
    public func customTitleArrowView(titleColor: UIColor) -> UIView? {
        return content.customTitleArrowView(titleColor: titleColor)
    }

    public var isDrawerEnabled: Bool {
        return true
    }

    public var needShowTitleArrow: BehaviorRelay<Bool> {
        if shouldShowOauthPage() {
            return BehaviorRelay(value: false)
        }
        return BehaviorRelay(value: true)
    }

    public var isNaviBarLoading: BehaviorRelay<Bool> {
        if shouldShowOauthPage() {
            return BehaviorRelay(value: false)
        }
        return content.navbarShowLoading
    }

    public var isNaviBarEnabled: Bool {
        return content.navbarEnable
    }

    public var titleText: BehaviorRelay<String> {
        if shouldShowOauthPage() {
            return BehaviorRelay(value: BundleI18n.MailSDK.Mail_Normal_Email)
        }
        return content.navbarTitle
    }

    public var subFilterTitleText: BehaviorRelay<String?> {
        if shouldShowOauthPage() {
            return BehaviorRelay(value: nil)
        }
        return content.navbarSubTitle
    }

    public func larkNaviBar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? {
        if shouldShowOauthPage() {
            return nil
        }
        return content.navbar(userDefinedButtonOf: type)
    }

    public func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        if shouldShowOauthPage() {
            return nil
        }
        return content.navbar(imageOfButtonOf: type)
    }

    public var isDefaultSearchButtonDisabled: Bool {
        return true
    }

    private func shouldShowOauthPage() -> Bool {
        if let vc = content as? MailHomeController {
            return vc.shouldShowOauthPage
        } else {
            return false
        }
    }
}

extension MailTabBarController: LarkNaviBarDelegate {
    public func onDefaultAvatarTapped() {
    }

    func onAvatarTapped() {
    }

    public func onTitleViewTapped() {
        if shouldShowOauthPage() {
            return
        }
        content.onNavTitleTapped()
    }

    public func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        if shouldShowOauthPage() {
            return
        }
        content.onNavButtonTapped(type: type)
    }
}

extension MailTabBarController: MailNavBarBridge, LarkNaviBarAbility {
    func changeLarkNaviBarTitleArrow(folded: Bool?, animated: Bool) {
        changeTitleArrowPresentation(folded: folded, animated: true)
    }

    func getLarkNaviBar() -> LarkNaviBar? {
        if let navBar = naviBar as? LarkNaviBar {
            return navBar
        }
        return nil
    }

    func reloadLarkNaviBar() {
        asyncRunInMainThread {
            self.reloadNaviBar()
        }
    }
}
