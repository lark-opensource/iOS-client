//
//  MailRoundedHud.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/21.
//

import Foundation
import EENavigator
import UniverseDesignToast
import LarkContainer

class MailRoundedHUD {
    class func showFailure(with text: String, on view: UIView) {
        UDToast.showFailure(with: text, on: findCurrentWindow(on: view))
    }

    class func showSuccess(with text: String, on view: UIView) {

        UDToast.showSuccess(with: text, on: findCurrentWindow(on: view))
    }

    class func showTips(with text: String, on view: UIView, delay: TimeInterval = 3.0) {
        UDToast.showTips(with: text, on: findCurrentWindow(on: view), delay: delay)
    }

    class func showWarning(with text: String, on view: UIView) {
        UDToast.showWarning(with: text, on: findCurrentWindow(on: view))
    }

    @discardableResult
    class func showLoading(with text: String? = nil, on view: UIView, disableUserInteraction: Bool = true) -> UDToast {
        return UDToast.showLoading(with: text ?? "", on: findCurrentWindow(on: view), disableUserInteraction: disableUserInteraction)
    }

    class func remove(on view: UIView) {
        UDToast.removeToast(on: findCurrentWindow(on: view))
    }

    private class func findCurrentWindow(on view: UIView) -> UIWindow {
        if let w = view as? UIWindow {
            return w
        }
        if let w = view.window, rightWindow(w: w) {
            return w
        } else if let w = Container.shared.getCurrentUserResolver().navigator.mainSceneWindow,
                  rightWindow(w: w) {
            /// 这里用 fallback 的方法，先看看有没有走，如果没走后续可以移除改分支
            mailAssertionFailure("[UserContainer] Should not fallback to main scene window")
            return w
        } else {
            mailAssertionFailure("can't find window")
            return UIWindow()
        }
    }
    private class func rightWindow(w: UIWindow) -> Bool {
        return !w.isHidden && w.windowLevel == .normal && w.alpha > 0
    }
}
