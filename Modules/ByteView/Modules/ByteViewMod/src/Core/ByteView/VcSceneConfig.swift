//
//  VcSceneConfig.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSceneManager
import ByteViewCommon
import ByteViewUI

@available(iOS 13.0, *)
final class VcSceneConfig: SceneConfig {
    static var key: String {
        SceneKey.vc.rawValue
    }

    static func icon() -> UIImage {
        VCAuxSceneService.icon()
    }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: Scene,
                             localContext: AnyObject?) -> UIViewController? {
        guard let info = sceneInfo.toVcSceneInfo() else {
            SceneManager.shared.deactive(from: scene)
            return nil
        }
        return VCAuxSceneService.createRootViewController(scene: scene, session: session, options: options, sceneInfo: info, localContext: localContext)
    }
}

@available(iOS 13.0, *)
final class VcSideBarSceneConfig: SceneConfig {
    static var key: String {
        SceneKey.vcSideBar.rawValue
    }

    static func icon() -> UIImage {
        VCAuxSceneService.icon()
    }

    static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: Scene,
                             localContext: AnyObject?) -> UIViewController?
    {
        guard let info = sceneInfo.toVcSceneInfo(), info.key == SceneKey.vcSideBar else {
            SceneManager.shared.deactive(from: scene)
            return nil
        }
        return VCSideBarSceneService.createRootViewController(scene: scene,
                                                              session: session,
                                                              options: options,
                                                              sceneInfo: info,
                                                              localContext: localContext)
    }
}

@available(iOS 13.0, *)
private extension Scene {
    func toVcSceneInfo() -> SceneInfo? {
        guard let key = SceneKey(rawValue: key) else { return nil }
        var info = SceneInfo(key: key, id: id)
        info.title = title
        info.windowType = windowType
        info.createWay = createWay
        info.userInfo = userInfo
        return info
    }
}
