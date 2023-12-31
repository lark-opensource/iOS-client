//
//  SceneDelegate.swift
//  AppContainer
//
//  Created by Meng on 2019/9/22.
//

import Foundation
import UIKit
import BootManager
import LarkSceneManager
import UniverseDesignTheme
import LarkExtensions

#if canImport(CryptoKit)
@available(iOS 13.0, *)
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    public var window: UIWindow?
    private var savedShortCutItem: UIApplicationShortcutItem?

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        let sceneInfo = scene.sceneInfo
        if sceneInfo.needRestoration,
           !sceneInfo.isMainScene() {
            let restorationScene = sceneInfo.restorationScene()
            return SceneTransformer.transform(scene: restorationScene)
        }
        return nil
    }

    private var context: AppInnerContext {
        assert(BootLoader.shared.context != nil)
        return BootLoader.shared.context ?? .default
    }

    func scene(_ scene: UIScene,
                    willConnectTo session: UISceneSession,
                    options connectionOptions: UIScene.ConnectionOptions) {
        assert(context.config.respondsToSceneSelectors)
        guard let scene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: scene)
        window.windowIdentifier = "AppContainer.SceneDelegate.window"
        self.window = window
        SceneManager.shared.setup(scene: scene, session: session, options: connectionOptions)
        NewBootManager.shared.boot(
            rootWindow: window,
            scene: scene,
            session: session,
            connectionOptions: connectionOptions
        )
        window.makeKeyAndVisible()
        // 和 AppDelegate 保持一致的兜底逻辑，启动时间较长时有 LaunchScreen 作为 rootVC 避免黑屏
        // 防止启动window没有rootVC crash
        for window in UIApplication.shared.windows where window.rootViewController == nil {
            let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
            let maskView = storyboard.instantiateInitialViewController()?.view ?? UIView()
            let tempVC = UIViewController()
            tempVC.view.addSubview(maskView)
            window.rootViewController = tempVC
        }

        let message = SceneWillConnectSession(context: context,
                                              session: session,
                                              scene: scene,
                                              connectionOptions: connectionOptions)
        context.dispatcher.send(message: message)
        if let shortcutItem = connectionOptions.shortcutItem {
            savedShortCutItem = shortcutItem
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        let message = SceneDidDisconnect(context: context, scene: scene)
        context.dispatcher.send(message: message)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        let message = SceneDidBecomeActive(context: context, scene: scene)
        context.dispatcher.send(message: message)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 咨询黄立兴后，先采用延迟手段解决冷启动无法感知feed页面是否加载完成。跳转扫一扫需要在feed加载后或启动完毕
            guard let shortCutItem = self.savedShortCutItem,
                  let scene = (scene as? UIWindowScene) else { return }
            let performActionMessage = WindowScenePerformAction(context: self.context, windowScene: scene, shortcutItem: shortCutItem, completionHandler: { _ in })
            self.context.dispatcher.send(message: performActionMessage)
            self.savedShortCutItem = nil
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        let message = SceneWillResignActive(context: context, scene: scene)
        context.dispatcher.send(message: message)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        let message = SceneWillEnterForeground(context: context, scene: scene)
        context.dispatcher.send(message: message)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        let message = SceneDidEnterBackground(context: context, scene: scene)
        context.dispatcher.send(message: message)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let message = SceneOpenURLContexts(context: context, scene: scene, urlContexts: URLContexts)
        context.dispatcher.send(message: message)
    }

    func windowScene(_ windowScene: UIWindowScene,
                          didUpdate previousCoordinateSpace: UICoordinateSpace,
                          interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
                          traitCollection previousTraitCollection: UITraitCollection) {
        let message = WindowSceneDidUpdateTraitCollection(context: context,
                                                          windowScene: windowScene,
                                                          previousCoordinateSpace: previousCoordinateSpace,
                                                          previousInterfaceOrientation: previousInterfaceOrientation,
                                                          previousTraitCollection: previousTraitCollection)
        context.dispatcher.send(message: message)
    }

    func windowScene(_ windowScene: UIWindowScene,
                          performActionFor shortcutItem: UIApplicationShortcutItem,
                          completionHandler: @escaping (Bool) -> Void) {
        let message = WindowScenePerformAction(context: context, windowScene: windowScene, shortcutItem: shortcutItem, completionHandler: completionHandler)
        context.dispatcher.send(message: message)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        let message = SceneContinueUserActivity(context: context, scene: scene, userActivity: userActivity)
        context.dispatcher.send(message: message)

        /// scene 被重新激活刷新 scene 相关数据
        SceneManager.shared.didContinue(scene: scene, userActivity: userActivity)
    }

    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        let message = SceneWillContinueUserActivity(context: context, scene: scene, userActivityType: userActivityType)
        context.dispatcher.send(message: message)
    }

    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        let message = SceneDidFailToContinueUserActivity(context: context, scene: scene, userActivityType: userActivityType, error: error)
        context.dispatcher.send(message: message)
    }

    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
        let message = SceneDidUpdateUserActivity(context: context, scene: scene, userActivity: userActivity)
        context.dispatcher.send(message: message)
    }
}
#endif
