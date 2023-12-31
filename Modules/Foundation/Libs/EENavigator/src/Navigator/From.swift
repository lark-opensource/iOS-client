//
//  From.swift
//  EENavigator
//
//  Created by 李晨 on 2020/8/26.
//

import UIKit
import Foundation

/// navigator from protocol, need provider one ViewController
public protocol NavigatorFrom: AnyObject {
    var fromViewController: UIViewController? { get }
    /// 是否可以被路由强持有
    var canBeStrongReferences: Bool { get }
}

extension NavigatorFrom {
    public var canBeStrongReferences: Bool {
        return true
    }
}

public final class NavigatorFromWrapper: NavigatorFrom {

    public weak var from: NavigatorFrom?

    private var strongFrom: NavigatorFrom?

    private weak var window: NavigatorFrom?

    private weak var scene: NavigatorFrom?

    public init(_ from: NavigatorFrom) {
        self.from = from

        /// 判断是否可以强行持有
        if from.canBeStrongReferences {
            self.strongFrom = from
        }

        /// 获取更多 UI context
        if let vc = from as? UIViewController {
            self.getUIContext(from: vc)
        } else if let window = from as? UIWindow {
            self.getUIContext(from: window)
        } else {
            if #available(iOS 13.0, *) {
                if let scene = from as? UIWindowScene {
                    self.getUIContext(from: scene)
                }
            }
        }
    }

    public var fromViewController: UIViewController? {
        return from?.fromViewController ??
            strongFrom?.fromViewController ??
            window?.fromViewController ??
            scene?.fromViewController
    }

    private func getUIContext(from vc: UIViewController) {
        if let window = vc.currentWindow() {
            self.getUIContext(from: window)
        }
    }

    private func getUIContext(from window: UIWindow) {
        self.window = window
        if #available(iOS 13.0, *) {
            if let scene = window.windowScene {
                self.getUIContext(from: scene)
            }
        }
    }

    @available(iOS 13.0, *)
    private func getUIContext(from scene: UIWindowScene) {
        self.scene = scene
    }
}

extension UIViewController: NavigatorFrom {
    public var fromViewController: UIViewController? {
        return self
    }

    public var canBeStrongReferences: Bool {
        return false
    }

    public func currentWindow() -> UIWindow? {
        // 这里之所以不用 ?? 是因为连续的 ?? 有非常差的编译性能问题
        // 此处如果全都换成 ?? 编译耗时需要 30,000 ~ 40,000s 以上，
        // 使用 if let { return } 则只需要小于 10ms 的耗时
        if let window = self.view.window { return window }
        if let window = self.presentedViewController?.currentWindow() { return window }
        if let window = self.navigationController?.view.window { return window }
        if let window = self.tabBarController?.view.window { return window }
        if let window = self.parent?.currentWindow() { return window }

        return nil
    }
}

extension UIWindow: NavigatorFrom {
    public var fromViewController: UIViewController? {
        if let root = self.rootViewController,
            let controller = UIViewController.topMost(of: root, checkSupport: true) {
            return controller
        }
        return nil
    }

    public var canBeStrongReferences: Bool {
        return false
    }
}

@available(iOS 13.0, *)
extension UIWindowScene: NavigatorFrom {
    public var fromViewController: UIViewController? {
        if let sceneDelegate = self.delegate as? UIWindowSceneDelegate,
            let root = sceneDelegate.window??.rootViewController,
               let controller = UIViewController.topMost(of: root, checkSupport: true) {
            return controller
        }
        return nil
    }

    public var canBeStrongReferences: Bool {
        return false
    }
}

/// 用于希望动态获取 window 的场景
/// 试用与 switchTab 之后跳转，以及 dismiss 只有跳转
public final class WindowTopMostFrom: NavigatorFrom {

    private weak var window: UIWindow?

    public init(window: UIWindow) {
        self.window = window
    }

    public init(vc: UIViewController) {
        self.window = vc.currentWindow()
        assert(self.window != nil, "当前 vc 已经获取不到 UI context 了")
    }

    public var fromViewController: UIViewController? {
        return window?.fromViewController
    }
}
