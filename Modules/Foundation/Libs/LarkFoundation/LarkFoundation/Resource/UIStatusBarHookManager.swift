//
//  Utils+StatusBar.swift
//  Pods
//
//  Created by 李勇 on 2019/7/30.
//  iOS13上状态栏由UIStatusBarManager管理
//

import UIKit
import Foundation

extension Notification {
    /// 点击状态栏通知
    public static let statusBarTapped = Notification(name: Notification.Name(rawValue: "statusBarTappedNotification"))
    /// 被点击次数, Int
    public static let statusBarTappedCount = "statusBarTappedCount"
    /// 点击横向位置, Double
    public static let statusBarTappedXPosition = "statusBarTappedXPosition"
    /// 在哪个 scene 内被点击, UIScene
    @available(iOS 13.0, *)
    public static let statusBarTappedInScene = "statusBarTappedInScene"
    /// 被点击的 statusBar 实例, UIStatusBarManager
    @available(iOS 13.0, *)
    public static let statusBarManagerThatTapped = "statusBarManagerThatTapped"
}

public class UIStatusBarHookManager: NSObject {
    // 短时间内点击次数
    static var StatusBarTapCount: Int = 0

    static var hooked: Bool = false
    // MARK: - StatusBarTap Hook 只有第一次调用生效，不会重复hook。非线程安全
    public class func hookTapEvent() {
        defer {
            Self.hooked = true
        }
        if !Self.hooked {
            if #available(iOS 13, *) {
                UIStatusBarHookManager.hookHandleScrollToTopAtXPosition()
            } else {
                UIStatusBarHookManager.hookUIApplication()
            }
        }
    }

    // 发通知，处理tap超时
    class func notificationAndHandleTapTimeOut(at xPosition: Double, statusBarManager: AnyObject? = nil) {
        UIStatusBarHookManager.StatusBarTapCount += 1
        var userInfo: [AnyHashable: Any] =
            [Notification.statusBarTappedCount:
                NSNumber(integerLiteral: UIStatusBarHookManager.StatusBarTapCount),
             Notification.statusBarTappedXPosition: xPosition]
        if #available(iOS 13.0, *) {
            UIApplication.shared.connectedScenes.forEach { scene in
                if let windowScene = scene as? UIWindowScene,
                   windowScene.statusBarManager === statusBarManager {
                    userInfo[Notification.statusBarTappedInScene] = windowScene
                }
            }
            userInfo[Notification.statusBarManagerThatTapped] = statusBarManager
        }
        NotificationCenter.default.post(
            name: Notification.statusBarTapped.name,
            object: self,
            userInfo: userInfo
        )
        NSObject.cancelPreviousPerformRequests(
            withTarget: UIStatusBarHookManager.self,
            selector: #selector(UIStatusBarHookManager.clearStatusBarTapCount),
            object: nil
        )
        UIStatusBarHookManager.perform(
            #selector(UIStatusBarHookManager.clearStatusBarTapCount),
            with: nil,
            afterDelay: 0.5
        )
    }
    @objc class func clearStatusBarTapCount() {
        UIStatusBarHookManager.StatusBarTapCount = 0
    }
}

// MARK: - Hook HandleScrollToTopAtXPosition
@available(iOS 13.0, *)
extension UIStatusBarHookManager {
    class func hookHandleScrollToTopAtXPosition() {
        let oldSelector = NSSelectorFromString("_handleScrollToTopAtXPosition:")
        let newSelector = NSSelectorFromString("hook_handleScrollToTopAtXPosition:")
        guard let imp = class_getMethodImplementation(self, newSelector) else { return }
        class_addMethod(UIStatusBarManager.self, newSelector, imp, "v@:d")
        guard let oldMethod = class_getInstanceMethod(UIStatusBarManager.self, oldSelector) else { return }
        guard let newMethod = class_getInstanceMethod(UIStatusBarManager.self, newSelector) else { return }
        method_exchangeImplementations(oldMethod, newMethod)
    }

    @objc func hook_handleScrollToTopAtXPosition(_ xOffset: Double) {
        self.hook_handleScrollToTopAtXPosition(xOffset)
        UIStatusBarHookManager.notificationAndHandleTapTimeOut(at: xOffset, statusBarManager: self)
    }
}

// MARK: - Hook UIApplication
extension UIStatusBarHookManager {
    class func hookUIApplication() {
        let oldSelector = NSSelectorFromString("_scrollsToTopInitiatorView:touchesEnded:withEvent:")
        let newSelector = NSSelectorFromString("statusTapHandler:touchesEnded:withEvent:")
        guard let imp = class_getMethodImplementation(self, newSelector) else { return }
        class_addMethod(UIApplication.self, newSelector, imp, "v@:@:@:@")
        guard let oldMethod = class_getInstanceMethod(UIApplication.self, oldSelector) else { return }
        guard let newMethod = class_getInstanceMethod(UIApplication.self, newSelector) else { return }
        method_exchangeImplementations(oldMethod, newMethod)
    }
    @objc func statusTapHandler(_ application: UIApplication, touchesEnded touches: Set<UITouch>, withEvent event: UIEvent) {
        self.statusTapHandler(application, touchesEnded: touches, withEvent: event)
        guard let touch = touches.first else { return }
        let xOffset = Double(touch.location(in: nil).x)
        UIStatusBarHookManager.notificationAndHandleTapTimeOut(at: xOffset)
    }
}

// MARK: - Check whether should response
public extension UIStatusBarHookManager {
    class func viewShouldResponse(of view: UIView, for notification: Notification) -> Bool {
        // 将 view 转换为在 window 中的坐标
        let absoluteRect = view.convert(view.bounds, to: nil)
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                // 先要过滤掉非 UIWindowScene 的 scene
                if let windowScene = scene as? UIWindowScene,
                   let statusBarManager =
                    notification.userInfo?[Notification.statusBarManagerThatTapped] as? UIStatusBarManager,
                   // 判断 view 和 被点击的 statusBarManager 处于同一个 windowScene
                   windowScene.statusBarManager === statusBarManager,
                   view.window?.windowScene === windowScene,
                   // 判断状态栏被点击的位置处于 view 的纵向范围
                   let xPosition = notification.userInfo?[Notification.statusBarTappedXPosition] as? Double,
                   absoluteRect.minX <= CGFloat(xPosition), absoluteRect.maxX >= CGFloat(xPosition) {
                    return true
                }
            }
            return false
        } else {
            if let xPosition = notification.userInfo?[Notification.statusBarTappedXPosition] as? Double,
               absoluteRect.minX <= CGFloat(xPosition), absoluteRect.maxX >= CGFloat(xPosition) {
                return true
            }
            return false
        }
    }
}
