//
//  RoundedHUD.swift
//  LarkUIKit
//
//  Created by zc on 2018/6/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignToast

public final class RoundedHUD {

    private var hud: UDToast?

    @available(*, deprecated, message:"Use UniverseDesignToast")
    @discardableResult
    public class func showLoading(
        with text: String? = nil,
        on view: UIView,
        disableUserInteraction: Bool = true) -> RoundedHUD {
        let text = text ?? BundleI18n.RoundedHUD.Lark_Legacy_BaseUiLoading

        let hud = UDToast.showLoading(with: text, on: view, disableUserInteraction: disableUserInteraction)
        let roundedHUD = RoundedHUD(hud: hud)
        return roundedHUD
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    @discardableResult
    public class func showTips(with text: String,
                               on view: UIView,
                               delay: TimeInterval = 3.0) -> RoundedHUD {
        let hud = UDToast.showTips(with: text, on: view, delay: delay)
        let roundedHUD = RoundedHUD(hud: hud)
        return roundedHUD
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    @discardableResult
    public class func showTipsOnScreenCenter(with text: String,
                                             on view: UIView,
                                             delay: TimeInterval = 3.0) -> RoundedHUD {
        let hud = UDToast.showTipsOnScreenCenter(with: text, on: view, delay: delay)
        let roundedHUD = RoundedHUD(hud: hud)
        return roundedHUD
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    @discardableResult
    public class func showFailure(with text: String, on view: UIView) -> RoundedHUD {
        let hud = UDToast.showFailure(with: text, on: view)
        let roundedHUD = RoundedHUD(hud: hud)
        return roundedHUD
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    @discardableResult
    public class func showSuccess(with text: String, on view: UIView) -> RoundedHUD {
        let hud = UDToast.showSuccess(with: text, on: view)
        let roundedHUD = RoundedHUD(hud: hud)
        return roundedHUD
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    public class func removeHUD(on view: UIView) {
        UDToast.removeToast(on: view)
    }

    public init() {
        self.hud = UDToast()
    }

    public init(hud: UDToast) {
        self.hud = hud
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    public func setCustomBottomMargin(_ margin: CGFloat) {
        hud?.setCustomBottomMargin(margin)
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    public func showFailure(with text: String, on view: UIView) {
        hud?.showFailure(with: text, on: view)
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    public func showSuccess(with text: String, on view: UIView) {
        hud?.showSuccess(with: text, on: view)
    }

    // 默认放到window上, 且不阻碍用户操作
    @available(*, deprecated, message:"Use UniverseDesignToast")
    public func showLoading(with text: String, on view: UIView) {
        self.showLoading(with: text, on: view, disableUserInteraction: false)
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    public func showLoading(with text: String, on view: UIView, disableUserInteraction: Bool = true) {
        hud?.showLoading(with: text, on: view, disableUserInteraction: disableUserInteraction)
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    public func showTips(with text: String, on view: UIView, delay: TimeInterval = 3.0) {
        hud?.showTips(with: text, on: view, delay: delay)
    }

    @available(*, deprecated, message:"Use UniverseDesignToast")
    public func remove() {
        hud?.remove()
    }
}

extension UDToast {
    @discardableResult
    public class func showDefaultLoading(
        with text: String? = nil,
        on view: UIView,
        disableUserInteraction: Bool = true) -> UDToast {
        let text = text ?? BundleI18n.RoundedHUD.Lark_Legacy_BaseUiLoading

        let hud = UDToast.showLoading(with: text, on: view, disableUserInteraction: disableUserInteraction)
        return hud
    }
}
