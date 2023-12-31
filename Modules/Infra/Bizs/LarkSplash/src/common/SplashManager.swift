//
//  LarkSplashManager.swift
//  LarkSplash
//
//  Created by 王元洵 on 2020/10/19.
//

import UIKit
import Foundation
import LarkSceneManager
import LarkExtensions

/// 开屏组件manager，负责展示开屏
public final class SplashManager {
    /// 全局单例
    public static let shareInstance = SplashManager()

    private var splashSDK: SplashSDK?

    private var hasRegister = false

    /// 展示开屏页面的window
    public let window: UIWindow = {
        let window = UIWindow()
        window.rootViewController = UIViewController()
        window.rootViewController?.view.isHidden = true
        window.windowLevel = .statusBar + 1
        if #available(iOS 13.0, *) {
            window.windowScene = SceneManager.shared.mainScene() as? UIWindowScene
        }
        window.backgroundColor = .clear
        window.windowIdentifier = "LarkSplash.SplashWindow"
        return window
    }()

    /// 是否是热启动
    public var isHotLaunch: Bool = false

    private init() { }

    // 只会保留第一个用户的ID（目前开平业务只对第一个用户展示开平），在切换租户以后，此ID会过期
    private(set) var userID: String?
    /// 注册SplashDelegate，弱持有delegate
    public func register(userID: String, delegate: SplashDelegate? = nil) {
        guard !hasRegister else { return }
        defer { hasRegister = true }
        self.userID = userID

        splashSDK = SplashSDK(splashDelegate: delegate ?? SplashManagerDelegateDefaultImpl.shared)
        splashSDK?.register()
    }

    /// 展示开屏页面
    public func displaySplash(isHotLaunch: Bool, fromIdle: Bool) {
        guard hasRegister, let splashSDK = splashSDK else {
            assertionFailure("需要先调用register方法")
            return
        }
        self.isHotLaunch = isHotLaunch
        SplashLogger.shared.info(event: "start splash", params: "isHotLaunch: \(isHotLaunch), idle: \(fromIdle)")
        splashSDK.displaySplash(onWindow: window, isHotLaunch: self.isHotLaunch, fromIdle: fromIdle)
    }

    func clearCache() {
        SplashLogger.shared.info(event: "clear resource cache")
        splashSDK?.clearCache()
    }
}
