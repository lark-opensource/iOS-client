//
//  SceneDelegate.swift
//  SceneDemo
//
//  Created by 李晨 on 2021/1/2.
//

import Foundation
import UIKit
import LarkSceneManager

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        window.makeKeyAndVisible()
        self.window = window
        SceneManager.shared.setup(scene: scene, session: session, options: connectionOptions)
        BootManager.shared.launch(
            context: [
                ContextKey.window: window,
                ContextKey.scene: scene,
                ContextKey.session: session,
                ContextKey.options: connectionOptions
            ]
        )
        print("sceneWillConnectTo \(scene.title!)")
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("sceneDidDisconnect \(scene.title!)")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("sceneDidBecomeActive \(scene.title!)")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("sceneWillResignActive \(scene.title!)")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("sceneWillEnterForeground \(scene.title!)")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("sceneDidEnterBackground \(scene.title!)")
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
    }

    func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace,
                     interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
                     traitCollection previousTraitCollection: UITraitCollection) {
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print("scene continue userActivity")
    }

    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
        print("scene didUpdate userActivity")
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("scene openURLContexts")
    }

    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        print("scene willContinueUserActivityWithType \(userActivityType)")
    }

    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        print("scene didFailToContinueUserActivityWithType \(userActivityType) \(error)")
    }

}
