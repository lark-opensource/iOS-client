//
//  SecuritySceneManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/2/23.
//

import Foundation
import LarkSceneManager
import LarkSecurityComplianceInfra

final class SecuritySceneManager {

    class func closeAllAssitantScenes() {
        if #available(iOS 13.0, *) {
            for uiScene in SceneManager.shared.windowApplicationScenes {
                let scene = uiScene.sceneInfo
                if !scene.isMainScene() {
                    SceneManager.shared.deactive(scene: scene)
                }
            }
            SCLogger.info("succeed to close all assistant scenes")
        } else { }
    }
}
