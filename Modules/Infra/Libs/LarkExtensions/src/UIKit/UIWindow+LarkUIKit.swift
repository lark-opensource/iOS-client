//
//  UIWindow+LarkUIKit.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/13.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import LarkCompatible
import UIKit

// swiftlint:disable identifier_name
private func getVisibleViewController(vc: UIViewController?, usePresentedVC: Bool = true) -> UIViewController? {
    // swiftlint:enable identifier_name
    guard let controller = vc else {
        return nil
    }
    if let nav = controller as? UINavigationController {
        // Return modal view controller if it exists. Otherwise the top view controller.
        return getVisibleViewController(vc: nav.topViewController, usePresentedVC: usePresentedVC)
    } else if let tabVc = controller as? UITabBarController {
        return getVisibleViewController(vc: tabVc.selectedViewController, usePresentedVC: usePresentedVC)
    } else {
        if usePresentedVC,
           let prensentedVc = controller.presentedViewController,
           prensentedVc.isBeingDismissed == false {
            return getVisibleViewController(vc: prensentedVc, usePresentedVC: usePresentedVC)
        } else {
            return controller
        }
    }
}

public extension LarkUIKitExtension where BaseType: UIWindow {
    func visibleViewController(usePresentedVC: Bool = true) -> UIViewController? {
        guard let rootVc = self.base.rootViewController else {
            return nil
        }
        return getVisibleViewController(vc: rootVc, usePresentedVC: usePresentedVC)
    }

    @available(*, deprecated, message: "此接口由于适配 UIScene 原因已废弃, 请选择其他接口")
    class func visibleViewController(usePresentedVC: Bool = true) -> UIViewController? {
        if let rootWindow = UIApplication.shared.delegate?.window {
            return rootWindow?.lu.visibleViewController(usePresentedVC: usePresentedVC)
        }
        return nil
    }
}

public extension LarkUIKitExtension where BaseType: UIWindow {

    // 由于后续需要支持多scene，所以将获取keyWindow的地方改为通过view获取rootWindow
    // 提供此方法，通过view获取rootWindow
    class func getRootWindowByView(_ view: UIView) -> UIWindow? {
        if #available(iOS 13.0, *) {
            if let window: UIWindow = view as? UIWindow ?? view.window,
               let scene = window.windowScene,
               let rootWindow = getRootWindowByScene(scene) {
                return rootWindow
            }
        }
        return getRootWindowByApplicatioDelagate()
    }
}

private var windowIdentifierKey: Void?
public extension UIWindow {
    /// window标识
    var windowIdentifier: String {
        get {
            return objc_getAssociatedObject(self, &windowIdentifierKey) as? String ?? "[window: not set identifier]"
        }
        set {
            objc_setAssociatedObject(self, &windowIdentifierKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

@available(iOS 13.0, *)
private func getRootWindowByScene(_ scene: UIWindowScene) -> UIWindow? {
    guard let delegate = scene.delegate as? UIWindowSceneDelegate else {
        return nil
    }
    return delegate.window.flatMap({ $0 })
}

private func getRootWindowByApplicatioDelagate() -> UIWindow? {
    guard let delegate = UIApplication.shared.delegate else {
        return nil
    }
    return delegate.window.flatMap({ $0 })
}
