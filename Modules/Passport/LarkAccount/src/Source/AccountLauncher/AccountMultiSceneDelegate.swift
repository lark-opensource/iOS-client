//
//  AccountMultiSceneDelegate.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2021/1/26.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import LarkSceneManager

class AccountMultiScenePassportDelegate: PassportDelegate {
    static let logger = Logger.plog(Launcher.self, category: "LarkAccount.AccountMultiSceneDelegate")
    var name = "AccountMultiSceneDelegate"

    func userDidOffline(state: PassportState) {
        let mainScene = Scene.mainScene()
        SceneManager.shared.active(scene: mainScene, from: nil) { (_, error) in
            if error == nil {
                Self.logger.info("succeed to activate main scene", method: .local)
                self.closeAllAssistantScenes()
            } else {
                Self.logger.info("failed to activate main scene")
            }
        }
    }
    
    private func closeAllAssistantScenes() {
        if #available(iOS 13.0, *) {
            for uiScene in UIApplication.shared.connectedScenes {
                let scene = uiScene.sceneInfo
                if !scene.isMainScene() {
                    SceneManager.shared.deactive(scene: scene)
                }
            }
            Self.logger.info("succeed to close all assistant scenes")
        }
    }
}

class AccountMultiSceneDelegate: LauncherDelegate { // user:checked
    static let logger = Logger.plog(Launcher.self, category: "LarkAccount.AccountMultiSceneDelegate")
    var name = "AccountMultiSceneDelegate"

    public func beforeLogout() {
        let mainScene = Scene.mainScene()
        SceneManager.shared.active(scene: mainScene, from: nil) { (_, error) in
            if error == nil {
                Self.logger.info("succeed to activate main scene")
                self.closeAllAssitantScenes()
            } else {
                Self.logger.info("failed to activate main scene")
            }
        }
    }

    private func closeAllAssitantScenes() {
        if #available(iOS 13.0, *) {
            for uiScene in UIApplication.shared.connectedScenes {
                let scene = uiScene.sceneInfo
                if !scene.isMainScene() {
                    SceneManager.shared.deactive(scene: scene)
                }
            }
            Self.logger.info("succeed to close all assistant scenes")
        }
    }
}
