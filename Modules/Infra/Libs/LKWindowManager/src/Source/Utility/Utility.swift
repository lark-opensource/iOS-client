//
//  Utility.swift
//  LKWindowManager
//
//  Created by 白镜吾 on 2022/10/29.
//

import Foundation
import UIKit

final public class Utility {
    /// 只在 iOS 16以下运行，打包机器暂不支持 unavailable 命令
    static func execOnlyUnderIOS16(_ block: @escaping () -> Void) {
        if #available(iOS 16, *) {
            return
        } else {
            block()
        }
    }

    /// 获取当前方向
    public static func getCurrentInterfaceOrientation() -> UIInterfaceOrientation? {
        if #available(iOS 13, *) {
            let windowScene = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene
            return windowScene?.interfaceOrientation
        }
        return UIApplication.shared.statusBarOrientation
    }

    /// 获取当前设备方向
    static func getCurrentDeviceOrientation() -> UIDeviceOrientation {
        var newDeviceOrientation: UIDeviceOrientation = .portrait
        guard let currentInterfaceOrientation = Utility.getCurrentInterfaceOrientation() else {
            return newDeviceOrientation
        }
        if currentInterfaceOrientation == .portrait {
            newDeviceOrientation = .portrait
        } else if currentInterfaceOrientation == .landscapeLeft {
            newDeviceOrientation = .landscapeRight
        } else if currentInterfaceOrientation == .landscapeRight {
            newDeviceOrientation = .landscapeLeft
        }
        return newDeviceOrientation
    }

    /// 获取当前允许的方向
    static func getCurrentOrientationMask() -> UIInterfaceOrientationMask {
        var newOrientationMask: UIInterfaceOrientationMask = .portrait
        guard let currentInterfaceOrientation = Utility.getCurrentInterfaceOrientation() else {
            return newOrientationMask
        }

        if currentInterfaceOrientation == .portrait {
            newOrientationMask = .portrait
        } else if currentInterfaceOrientation == .landscapeLeft || currentInterfaceOrientation == .landscapeRight {
            newOrientationMask = [.landscapeLeft, .landscapeRight]
        }
        return newOrientationMask
    }

    @available(iOS 13.0, *)
    public static func findForegroundActiveScene() -> UIWindowScene? {
        return UIApplication.shared.connectedScenes.first { (scene) -> Bool in
            return scene.activationState == .foregroundActive && scene.session.role == .windowApplication
        } as? UIWindowScene
    }

    @available(iOS 13.0, *)
    public static func rootWindowForScene(scene: UIScene) -> UIWindow? {
        guard let scene = scene as? UIWindowScene else {
            return nil
        }
        if let delegate = scene.delegate as? UIWindowSceneDelegate,
           let rootWindow = delegate.window.flatMap({ $0 }) {
            return rootWindow
        }
        return scene.windows.first
    }

    public static func focusRotateIfNeeded(to orientation: UIDeviceOrientation) {
        UIDevice.current.setValue(UIDeviceOrientation.unknown.rawValue, forKey: "orientation")
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }

    @available(iOS 16.0, *)
    public static func focusRotateIfNeeded(to interfaceOrientations: UIInterfaceOrientationMask, window: UIWindow, windowScene: UIWindowScene) {
        window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: interfaceOrientations))
    }

    /*
    /// 是否处于横屏
    static var isLandscape: Bool {
        if let isLandscape = Utility.getCurrentInterfaceOrientation()?.isLandscape {
            return isLandscape
        }
        let screenSize = Utility.getCurrentScreen().bounds
        return screenSize.width > screenSize.height
    }

    /// 是否处于竖屏
    static var isPortrait: Bool {
        return !isLandscape
    }

    /// 当前 APP 内的 key Window
    static var appKeyWindow: UIWindow? {
        var windows: [UIWindow]?

        if #available(iOS 13.0, *) {
            windows = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive && $0.session.role == .windowApplication })
                .map({ $0 as? UIWindowScene })
                .compactMap({ $0 })
                .last?.windows

        } else {
            windows = UIApplication.shared.windows
        }

        guard let windows = windows else {
            return nil
        }

        var lastWindow: UIWindow? = windows.last
        for window in windows.reversed() {
            guard !window.isHidden else { continue }
            switch (window.isKeyWindow, window.isKind(of: LKWindow.self)) {
            case (true, true):
                if let previousKeyWindow = (window as? LKWindow)?.previousKeyWindow {
                    return previousKeyWindow
                } else {
                    lastWindow = window
                    continue
                }
            case (true, false):
                return window
            case (false, _):
                lastWindow = window
                return window
            }
        }
        return lastWindow
    }

    /// 获取当前允许的方向
    static func getSupportedInterfaceOrientationMask() -> UIInterfaceOrientationMask {
        var viewControllerToAsk = Utility.viewControllerForRotationAndOrientation()
        var supportedOrientations: UIInterfaceOrientationMask = .portrait

        if let viewControllerToAsk = viewControllerToAsk,
           !viewControllerToAsk.isKind(of: LKWindowRootController.self) {
            supportedOrientations = viewControllerToAsk.supportedInterfaceOrientations
        }

        if supportedOrientations.rawValue == 0 {
            supportedOrientations = .all
        }
        return supportedOrientations
    }

    static func getCurrentScreen() -> UIScreen {
        if #available(iOS 13, *),
           let windowScene = UIApplication.shared.connectedScenes.first(where: { return $0.session.role == .windowApplication }) as? UIWindowScene {
            return windowScene.screen
        }
        return UIScreen.main
    }

    /// 获取 keywindow 的 viewcontroller
    static func viewControllerForRotationAndOrientation() -> UIViewController? {
        var viewController = Utility.appKeyWindow?.rootViewController
        var viewControllerSelectorString = ["_vie", "wContro", "llerFor", "Supported", "Interface", "Orientations"].joined(separator: ",")
        var viewControllerSelector = Selector(viewControllerSelectorString)
        if viewController?.responds(to: viewControllerSelector) ?? false {
            viewController = viewController?.value(forKey: viewControllerSelectorString) as? UIViewController
        }
        return viewController
    }
     */
}
