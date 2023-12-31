//
//  TopMost.swift
//  ByteView
//
//  Created by kiri on 2021/3/31.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    var topMost: UIViewController {
        UIViewController.topMost(of: self)
    }

    static var topMost: UIViewController? {
        if let kw = UIApplication.shared.windows.keyWindow, let vc = kw.rootViewController {
            return vc.topMost
        }

        let windows = UIApplication.shared.windows.reversed()
        for window in windows {
            if !window.isHidden, let vc = window.rootViewController {
                return vc.topMost
            }
        }
        return nil
    }

    /// Returns the top most view controller from given view controller's stack.
    private static func topMost(of viewController: UIViewController) -> UIViewController {
        // presented view controller
        if let presentedViewController = viewController.presentedViewController {
            if presentedViewController.isBeingDismissed || presentedViewController.isMovingFromParent {
                return presentedViewController.presentingViewController ?? viewController
            } else {
                return self.topMost(of: presentedViewController)
            }
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController, let selectedViewController = tabBarController.selectedViewController {
            return topMost(of: selectedViewController)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return topMost(of: visibleViewController)
        }

        // detailvc is the topmost vc
        if let lastVC = (viewController as? UISplitViewController)?.viewControllers.last {
            return topMost(of: lastVC)
        }

        // child view controller
        for subview in viewController.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return topMost(of: childViewController)
            }
        }
        return viewController
    }
}

extension UIWindow {
    var topMost: UIViewController? {
        rootViewController?.topMost
    }

    /// window大小是否等于scene大小
    var isFullSize: Bool {
        if #available(iOS 13, *), let scene = windowScene {
            return bounds.size.equalSizeTo(scene.coordinateSpace.bounds.size)
        } else if let ow = UIApplication.shared.delegate?.window, let w = ow {
            return bounds.size.equalSizeTo(w.bounds.size)
        } else {
            return bounds.size.equalSizeTo(screen.bounds.size)
        }
    }
}

@available(iOS 13.0, *)
extension UIApplication {
    /// foreground keyWindow -> active -> foreground -> keyWindow -> any
    var topMostScene: UIWindowScene? {
        let scenes = windowScenes
        let foregroundScenes = scenes.filter {
            $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }
        if let scene = foregroundScenes.first(where: { $0.windows.contains { $0.isKeyWindow } }) {
            return scene
        }
        if let scene = foregroundScenes.first(where: { $0.activationState == .foregroundActive }) {
            return scene
        }
        if let scene = foregroundScenes.first {
            return scene
        }
        if let scene = scenes.first(where: { $0.windows.contains { $0.isKeyWindow } }) {
            return scene
        }
        return scenes.first
    }

    var windowScenes: [UIWindowScene] {
        connectedScenes.compactMap { $0 as? UIWindowScene }
    }
}

extension UIApplication {
    /// kw -> same scene -> other
    func fullSizeWindow(except window: UIWindow? = nil) -> UIWindow? {
        if let kw = windows.keyWindow, kw != window, kw.isFullSize {
            return kw
        }
        // 先找同scene，再找其他
        if #available(iOS 13, *), let window = window?.windowScene?.windows.fullSizeWindow(except: window) {
            return window
        } else {
            return windows.fullSizeWindow(except: window)
        }
    }
}

extension Array where Element == UIWindow {
    var keyWindow: UIWindow? {
        first(where: { $0.isKeyWindow })
    }

    func fullSizeWindow(except window: UIWindow? = nil) -> UIWindow? {
        first(where: { !$0.isHidden && $0 != window && $0.isFullSize })
    }
}
