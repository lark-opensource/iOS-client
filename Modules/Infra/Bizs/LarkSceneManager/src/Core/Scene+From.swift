//
//  Scene+From.swift
//  LarkSceneManager
//
//  Created by 李晨 on 2021/1/17.
//

import Foundation
import UIKit

/// 用于获取当前 scene 来源
public protocol SceneFrom {
    /// 返回当前 scene
    @available(iOS 13.0, *)
    func currentScene() -> UIScene?

    /// 放回 sceneFrom 所在 window
    func rootWindow() -> UIWindow?
}

@available(iOS 13.0, *)
extension UIScene: SceneFrom {
    /// 返回当前 scene
    public func currentScene() -> UIScene? {
        return self
    }

    /// 返回当前 window
    public func rootWindow() -> UIWindow? {
        if let windowScene = self as? UIWindowScene,
           let delegate = windowScene.delegate as? UIWindowSceneDelegate {
                return delegate.window?.map({ $0 })
            }
        return nil
    }
}

extension UIWindow: SceneFrom {
    /// 返回当前 scene
    @available(iOS 13.0, *)
    public func currentScene() -> UIScene? {
        return self.windowScene
    }

    public func rootWindow() -> UIWindow? {
        return self
    }
}

extension UIViewController: SceneFrom {
    /// 返回当前 scene
    @available(iOS 13.0, *)
    public func currentScene() -> UIScene? {
        return self.rootWindow()?.windowScene
    }

    public func rootWindow() -> UIWindow? {
        // 这里之所以不用 ?? 是因为连续的 ?? 有非常差的编译性能问题
        // 此处如果全都换成 ?? 编译耗时需要 30,000 ~ 40,000s 以上，
        // 使用 if let { return } 则只需要小于 10ms 的耗时
        if let window = self.view.window { return window }
        if let window = self.presentedViewController?.rootWindow() { return window }
        if let window = self.navigationController?.view.window { return window }
        if let window = self.tabBarController?.view.window { return window }
        if let window = self.parent?.rootWindow() { return window }

        return nil
    }

    /// 返回当前 scene session persistentIdentifier
    public func currentSceneID() -> String? {
        guard #available(iOS 13.0, *),
            let scene = self.currentScene() else {
            return nil
        }
        return scene.session.persistentIdentifier
    }
}
