//
//  LkWindowManager+VirtualWindow.swift
//  LKWindowManager
//
//  Created by Yaoguoguo on 2022/12/15.
//

import UIKit
import Foundation

open class LKVirtualWindow: UIView, LKWindowProtocol {
    open class func canCreate(by config: VirtualWindowConfig) -> Bool {
        return false
    }

    open class func create(by config: VirtualWindowConfig) -> LKVirtualWindow? {
        let virtualwindow = LKVirtualWindow()
        virtualwindow.identifier = config.identifier.rawValue
        virtualwindow.windowLevel = config.level
        return virtualwindow
    }

    open var identifier: String = ""

    /// Real UIWindow
    weak open private(set) var superWindow: LKWindow?

    open var rootViewController: UIViewController? {
        didSet {
            self.addRootViewController(rootViewController)
        }
    }

    open var windowLevel: UIWindow.Level = .normal

    open var canResizeToFitContent: Bool = false

    open var isKeyWindow: Bool = false

    open var canBecomeKey: Bool = true

    @available(iOS 13.0, *)
    weak open var windowScene: UIWindowScene? {
        get {
            return superWindow?.windowScene
        }
        set {
            superWindow?.windowScene = newValue
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.rootViewController?.view.frame = self.bounds
    }

    open func setSuperWindow(_ window: LKWindow) {
        self.superWindow = window
        self.addRootViewController(rootViewController)
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }
        if hitView == self {
            return nil
        }
        return hitView
    }

    public override func removeFromSuperview() {
        self.superWindow?.removeVirtualWindow(self)
        self.superWindow = nil
        self.rootViewController?.removeFromParent()
        self.rootViewController?.view.removeFromSuperview()

        super.removeFromSuperview()
    }

    public func addRootViewController(_ rootViewController: UIViewController?) {
        guard let viewController = rootViewController else { return }
        viewController.removeFromParent()
        viewController.view.removeFromSuperview()
        self.addSubview(viewController.view)
        self.superWindow?.addVirtualWindowVC(viewController)
    }

    open func makeKeyAndVisible() {
        self.superWindow?.makeKeyByVirtualWindow(self, isVisible: true)
    }

    open func makeKey() {
        self.superWindow?.makeKeyByVirtualWindow(self, isVisible: false)
    }

    open func becomeKey() {

    }

    open func resignKey() {

    }

    open func convert(_ point: CGPoint, to window: UIWindow?) -> CGPoint {
        guard let superWindow = self.superWindow else {
            assertionFailure("Super Window is nil")
            return .zero
        }
        return superWindow.convert(point, to: window)
    }

    open func convert(_ point: CGPoint, from window: UIWindow?) -> CGPoint {
        guard let superWindow = self.superWindow else {
            assertionFailure("Super Window is nil")
            return .zero
        }
        return superWindow.convert(point, from: window)
    }

    open func convert(_ rect: CGRect, to window: UIWindow?) -> CGRect {
        guard let superWindow = self.superWindow else {
            assertionFailure("Super Window is nil")
            return .zero
        }
        return superWindow.convert(rect, to: window)
    }

    open func convert(_ rect: CGRect, from window: UIWindow?) -> CGRect {
        guard let superWindow = self.superWindow else {
            assertionFailure("Super Window is nil")
            return .zero
        }
        return superWindow.convert(rect, from: window)
    }

    open func tranformToLarkWindow() -> LKWindow? {
        return nil
    }
}
