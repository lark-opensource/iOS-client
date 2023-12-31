//
//  AnimatedTabBarController+Hook.swift
//  AnimatedTabBar
//
//  Created by Yaoguoguo on 2023/10/30.
//

import Foundation

extension DispatchQueue {

    private static var onceTokenTracker: [String] = []
    /// 保证整个生命周期只执行一次
    ///
    /// - Parameters:
    ///   - token: token
    ///   - block: 执行的代码块
    static func dispatchOnce(_ token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if onceTokenTracker.contains(token) {
            return
        }
        onceTokenTracker.append(token)
        block()
    }

}

extension UIView {

    private static let onceToken = UUID().uuidString

    static func initializeOnceForView() {
        guard self == UIView.self else { return }
        DispatchQueue.dispatchOnce(onceToken) {
            let swizzleSelectors = [
                NSSelectorFromString("layoutSubviews"),
            ]
            for selector in swizzleSelectors {
                let newSelector = ("swizzle_" + selector.description)
                if let originalMethod = class_getInstanceMethod(self, selector),
                   let swizzledMethod = class_getInstanceMethod(self, Selector(newSelector)) {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
            }
        }
    }

    @objc
    func swizzle_layoutSubviews() {
        swizzle_layoutSubviews()

        let inBackground: Bool = { () -> Bool in
            if #available(iOS 13, *),
               let windowScene = self.window?.windowScene {
                return windowScene.activationState == .background
            } else {
                return UIApplication.shared.applicationState == .background
            }
        }()

        if inBackground {
            AnimatedTabBarController.logger.info("UIView layoutSubviews self: \(self.tkClassName), \(self.nodeViewController?.tkClassName ?? "")")
        }
    }
}
