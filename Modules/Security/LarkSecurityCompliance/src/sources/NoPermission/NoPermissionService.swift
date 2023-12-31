//
//  NoPermissionService.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/7.
//

import UIKit
import LarkUIKit
import LarkSceneManager
import LarkAccountInterface
import LarkSecurityComplianceInfra
import LarkContainer

protocol NoPermissionService {
    func showViewController(_ controller: UIViewController)

    func dismissCurrentWindow()

    var isInNoPermision: Bool { get }
    var isNoPermissionViewShowing: Bool { get }

    var currentVC: UIViewController? { get }
}

private let windowLevel = UIWindow.Level.alert - 3

@available(iOS 13.0, *)
fileprivate extension UIScene {
    var isAppMainScene: Bool {
        self.session.role == .windowApplication && self.sceneInfo.isMainScene()
    }
}

final class NoPermissionServiceImp: NoPermissionService, SecurityComplianceDependency {

    private var window: LSCWindow?
    private var observers: [AnyObject] = []

    let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
        if #available(iOS 13, *) {
            observeSceneNotification()
        }
    }

    deinit {
        dismissCurrentWindow()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    var currentVC: UIViewController? {
        return window?.rootViewController?.children.first
    }

    var isInNoPermision: Bool {
        if let vc = currentVC as? NoPermissionViewController {
            // refreshing表示用户手动点击重新访问，这个时候以最新的决策为准
            return !vc.viewModel.isRefreshing
        }
        return false
    }

    var isNoPermissionViewShowing: Bool {
        return currentVC is NoPermissionViewController
    }

    func showViewController(_ controller: UIViewController) {
        LayoutConfig.currentWindow?.endEditing(true)

        let controller = LkNavigationController(rootViewController: controller)
        if #available(iOS 13, *) {
            setupWindowByConnectScene(rootVC: controller)
        } else {
            setupWindowByApplicationDelegate(rootVC: controller)
        }

        window?.isHidden = false
        window?.becomeFirstResponder()
    }

    func dismissCurrentWindow() {
        window?.resignFirstResponder()
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
    }

    func securityComplianceWindow() -> UIWindow? {
        if let window = self.window, !window.isHidden {
            return window
        }
        return nil
    }

    private func createWindowIfNeeded(rootWindow: UIWindow, rootVC: UIViewController) {
        guard window == nil else {
            window?.rootViewController = rootVC
            if #available(iOS 13.0, *) {
                window?.windowScene = rootWindow.windowScene
            }
            return
        }
        window = LSCWindow(resolver: userResolver, frame: rootWindow.bounds)
        if #available(iOS 13.0, *) {
            window?.windowScene = rootWindow.windowScene
        }
        window?.windowLevel = windowLevel
        window?.rootViewController = rootVC
        window?.isHidden = true
    }

    @available(iOS 13.0, *)
    private func setupWindowByConnectScene(rootVC: UIViewController) {
        closeAllAssitantScenes()

        if let scene = SceneManager.shared.windowApplicationScenes.first(where: { $0.isAppMainScene }),
           let windowScene = scene as? UIWindowScene,
           let rootWindow = rootWindowForScene(scene: windowScene) {
            createWindowIfNeeded(rootWindow: rootWindow, rootVC: rootVC)
            Logger.info("NoPermission: setupWindowByConnectScene: \(windowScene) \(rootWindow)")
        }
    }

    private func setupWindowByApplicationDelegate(rootVC: UIViewController) {
        guard let delegate = UIApplication.shared.delegate,
              let weakWindow = delegate.window,
              let rootWindow = weakWindow else {
            return
        }

        createWindowIfNeeded(rootWindow: rootWindow, rootVC: rootVC)
    }

    @available(iOS 13.0, *)
    private func observeSceneNotification() {
        let didActivateObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                guard let scene = noti.object as? UIWindowScene,
                      let windowScene = self?.window?.windowScene else {
                    return
                }
                if scene.isAppMainScene {
                    self?.window?.windowScene = scene
                    Logger.info("NoPermission: didActivateNotification: \(scene), currentWindowScene: \(windowScene)")
                }
        }

        let didDisconnectObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                guard let scene = noti.object as? UIWindowScene else {
                    return
                }
                if self?.window?.windowScene == scene {
                    self?.window?.windowScene = self?.findForegroundActiveScene()
                    Logger.info("NoPermission: didDisconnectNotification: \(scene)")
                }
        }
        observers = [didActivateObserver, didDisconnectObserver]
    }

    @available(iOS 13.0, *)
    private func closeAllAssitantScenes() {
        for uiScene in SceneManager.shared.windowApplicationScenes {
            let scene = uiScene.sceneInfo
            if !scene.isMainScene() {
                SceneManager.shared.deactive(scene: scene)
            }
        }
        Logger.info("succeed to close all assistant scenes")
    }

    @available(iOS 13.0, *)
    private func findForegroundActiveScene() -> UIWindowScene? {
        return SceneManager.shared.windowApplicationScenes.first { $0.isAppMainScene } as? UIWindowScene
    }

    @available(iOS 13.0, *)
    private func rootWindowForScene(scene: UIScene) -> UIWindow? {
        guard let scene = scene as? UIWindowScene else {
            return nil
        }
        if let delegate = scene.delegate as? UIWindowSceneDelegate,
           let rootWindow = delegate.window.flatMap({ $0 }) {
            return rootWindow
        }
        return scene.windows.first
    }
}
